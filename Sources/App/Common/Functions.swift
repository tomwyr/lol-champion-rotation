func runRetrying<T>(
  retryDelays: [Duration],
  errorFilter: ((any Error) -> Bool)? = nil,
  _ block: () async throws -> T
) async throws -> T {
  var retry = 0
  while 0...retryDelays.count ~= retry {
    do {
      return try await block()
    } catch {
      if let errorFilter {
        guard errorFilter(error) else {
          throw error
        }
      }
      guard let delay = retryDelays[try: retry] else {
        throw error
      }
      try await runDelay(delay)
      retry += 1
    }
  }
  fatalError(
    "The 'runRetrying' function did not return a result or throw an error after \(retryDelays.count) attempts."
  )
}
