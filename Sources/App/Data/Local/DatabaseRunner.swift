import Fluent
import FluentPostgresDriver

protocol DatabaseRunner {
  func run<T>(block: (Database) async throws -> T) async throws -> T
}

struct RetryingRunner: DatabaseRunner {
  let database: Database

  func run<T>(block: (Database) async throws -> T) async throws -> T {
    try await runRetrying(
      block: { try await block(database) },
      retryDelays: [.seconds(2), .seconds(3), .seconds(5)],
      errorFilter: isStartupError
    )
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
