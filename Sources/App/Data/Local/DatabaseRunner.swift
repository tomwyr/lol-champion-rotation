import Fluent
import FluentPostgresDriver

protocol DatabaseRunner: Sendable {
  func run<T>(block: (Database) async throws -> T) async throws -> T
  func runSql<T>(block: (SQLDatabase) async throws -> T) async throws -> T
}

struct StartupRetryRunner: DatabaseRunner, RunRetrying {
  let database: Database

  func run<T>(block: (Database) async throws -> T) async throws -> T {
    try await runRetrying {
      try await block(database)
    }
  }

  func runSql<T>(block: (SQLDatabase) async throws -> T) async throws -> T {
    try await runRetrying {
      guard let database = database as? SQLDatabase else {
        fatalError("The underlying database isn't an SQL database.")
      }
      return try await block(database)
    }
  }

  private func runRetrying<T>(block: () async throws -> T) async throws -> T {
    try await runRetrying(
      retryDelays: [.seconds(2), .seconds(3), .seconds(5)],
      errorFilter: isStartupError
    ) {
      try await block()
    }
  }

  private func isStartupError(_ error: any Error) -> Bool {
    switch error {
    case let error as PSQLError where error.code == .serverClosedConnection:
      true
    case NIOCore.ChannelError.ioOnClosedChannel:
      true
    default:
      false
    }
  }
}
