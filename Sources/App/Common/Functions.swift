import Logging

/// Wrap in a protocol because, if defined as a global function, the LSP
/// analyzer produces error about clock's default value type conformance.
protocol RunRetrying {
  func runRetrying<T, C>(
    retryDelays: [C.Instant.Duration],
    errorFilter: ((any Error) -> Bool)?,
    clock: C,
    logger: Logger,
    _ task: () async throws -> T
  ) async throws -> T where C: Clock
}

extension RunRetrying {
  func runRetrying<T, C>(
    retryDelays: [C.Instant.Duration],
    errorFilter: ((any Error) -> Bool)? = nil,
    clock: C = ContinuousClock(),
    logger: Logger = .default(),
    _ task: () async throws -> T
  ) async throws -> T where C: Clock {
    var retry = 0
    while 0...retryDelays.count ~= retry {
      do {
        let result = try await task()
        if retry > 0 {
          logger.retrySucceeded(attempt: retry)
        }
        return result
      } catch {
        if let errorFilter {
          guard errorFilter(error) else {
            logger.unhandledError(cause: error)
            throw error
          }
        }

        guard let delay = retryDelays[try: retry] else {
          logger.outOfRetries(maxCount: retryDelays.count, cause: error)
          throw error
        }

        logger.schedulingRetry(delay: delay, cause: error)
        try await Task.sleep(for: delay, clock: clock)
        retry += 1
      }
    }
    fatalError(
      "The 'runRetrying' function did not return a result or throw an error after \(retryDelays.count) attempt(s)."
    )
  }
}

extension Logger {
  fileprivate func unhandledError(cause: any Error) {
    warning("Unhandled error: \(cause), propagating to caller")
  }

  fileprivate func outOfRetries(maxCount: Int, cause: any Error) {
    warning("Retries exhausted after \(maxCount) attempts. Last error: \(cause)")
  }

  fileprivate func schedulingRetry(delay: any DurationProtocol, cause: any Error) {
    info("Scheduling retry in \(delay) due to error: \(cause)")
  }

  fileprivate func retrySucceeded(attempt: Int) {
    info("Task succeeded after \(attempt) retry(ies)")
  }
}
