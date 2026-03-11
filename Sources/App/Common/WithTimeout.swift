/// Wrap in a protocol because, if defined as a global function, the LSP
/// analyzer produces error about clock's default value type conformance.
/// The issue should be fixed in Swift 6.3.
protocol WithTimeout {
  func withTimeout<T, C>(
    of duration: C.Instant.Duration,
    clock: C,
    operation: @Sendable @escaping () async throws -> T,
  ) async throws -> T where T: Sendable, C: Clock
}

extension WithTimeout {
  /// Executes an asynchronous operation with a timeout.
  /// Throws `TaskTimeoutError.timedOut` if the operation does not complete
  /// within the specified duration.
  func withTimeout<T, C>(
    of duration: C.Instant.Duration,
    clock: C = ContinuousClock(),
    operation: @Sendable @escaping () async throws -> T,
  ) async throws -> T where T: Sendable, C: Clock {
    try await withThrowingTaskGroup { group in
      defer { group.cancelAll() }
      group.addTask(operation: operation)
      group.addTask {
        try await Task.sleep(for: duration, clock: clock)
        throw TaskTimeoutError.timedOut
      }
      return try await group.next()!
    }
  }
}

/// Error thrown when an asynchronous operation times out.
enum TaskTimeoutError: Error {
  case timedOut
}
