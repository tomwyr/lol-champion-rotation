/// Wrap in a protocol because, if defined as a global function, the LSP
/// analyzer produces error about clock's default value type conformance.
protocol RunRetrying {
  func runRetrying<T, C>(
    retryDelays: [C.Instant.Duration],
    errorFilter: ((any Error) -> Bool)?,
    clock: C,
    _ task: () async throws -> T
  ) async throws -> T where C: Clock
}

extension RunRetrying {
  func runRetrying<T, C>(
    retryDelays: [C.Instant.Duration],
    errorFilter: ((any Error) -> Bool)? = nil,
    clock: C = ContinuousClock(),
    _ task: () async throws -> T
  ) async throws -> T where C: Clock {
    var retry = 0
    while 0...retryDelays.count ~= retry {
      do {
        return try await task()
      } catch {
        if let errorFilter {
          guard errorFilter(error) else {
            throw error
          }
        }
        guard let delay = retryDelays[try: retry] else {
          throw error
        }
        try await Task.sleep(for: delay, clock: clock)
        retry += 1
      }
    }
    fatalError(
      "The 'runRetrying' function did not return a result or throw an error after \(retryDelays.count) attempt(s)."
    )
  }
}
