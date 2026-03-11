import AsyncKit
import Fluent
import FluentPostgresDriver

protocol DatabaseRunner: Sendable, RunRetrying, WithTimeout {
  func run<T: Sendable>(
    timeout: Duration,
    block: @escaping @Sendable (Database) async throws -> T,
  ) async throws -> T

  func runSql<T: Sendable>(
    timeout: Duration,
    block: @escaping @Sendable (SQLDatabase) async throws -> T,
  ) async throws -> T
}

extension DatabaseRunner {
  func run<T: Sendable>(
    timeout: Duration = .seconds(1),
    block: @escaping @Sendable (Database) async throws -> T,
  ) async throws -> T {
    try await run(timeout: timeout, block: block)
  }

  func runSql<T: Sendable>(
    timeout: Duration = .seconds(1),
    block: @escaping @Sendable (SQLDatabase) async throws -> T,
  ) async throws -> T {
    try await runSql(timeout: timeout, block: block)
  }
}

struct DefaultDatabaseRunner: DatabaseRunner {
  let database: Database

  func run<T: Sendable>(
    timeout: Duration,
    block: @escaping @Sendable (Database) async throws -> T,
  ) async throws -> T {
    try await withTimeout(of: timeout) {
      try await block(database)
    }
  }

  func runSql<T: Sendable>(
    timeout: Duration,
    block: @escaping @Sendable (SQLDatabase) async throws -> T,
  ) async throws -> T {
    try await withTimeout(of: timeout) {
      guard let database = database as? SQLDatabase else {
        fatalError("The underlying database isn't an SQL database.")
      }
      return try await block(database)
    }
  }
}

struct StartupRetryRunner: DatabaseRunner {
  let database: Database
  let logger: Logger

  func run<T: Sendable>(
    timeout: Duration,
    block: @escaping @Sendable (Database) async throws -> T,
  ) async throws -> T {
    try await runRetrying {
      try await withTimeout(of: timeout) {
        try await block(database)
      }
    }
  }

  func runSql<T: Sendable>(
    timeout: Duration,
    block: @escaping @Sendable (SQLDatabase) async throws -> T,
  ) async throws -> T {
    try await runRetrying {
      try await withTimeout(of: timeout) {
        guard let database = database as? SQLDatabase else {
          fatalError("The underlying database isn't an SQL database.")
        }
        do {
          return try await block(database)
        } catch {
          logger.warning(.init(stringLiteral: String(describing: error)))
          throw error
        }
      }
    }
  }

  private func runRetrying<T>(block: () async throws -> T) async throws -> T {
    try await runRetrying(
      retryDelays: [.seconds(2), .seconds(3), .seconds(5)],
      errorFilter: isStartupError,
      logger: logger,
    ) {
      try await block()
    }
  }

  private func isStartupError(_ error: any Error) -> Bool {
    switch error {
    case let error as PSQLError
    where error.code == .serverClosedConnection
      || error.code == .server && error.serverCode == .cannotConnectNow:
      true
    case NIOCore.ChannelError.ioOnClosedChannel,
      AsyncKit.ConnectionPoolTimeoutError.connectionRequestTimeout:
      true
    case is TaskTimeoutError:
      true
    default:
      false
    }
  }
}

private enum PSQLErrorServerCode: String, CaseIterable {
  case cannotConnectNow = "57P03"
}

extension PSQLError {
  fileprivate var serverCode: PSQLErrorServerCode? {
    if let code = serverInfo?[.sqlState] {
      PSQLErrorServerCode.allCases.first { $0.rawValue == code }
    } else {
      nil
    }
  }
}
