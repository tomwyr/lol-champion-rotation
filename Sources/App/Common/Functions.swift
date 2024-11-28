func runRetrying<T>(
  block: () async throws -> T,
  retryDelays: [Duration],
  errorFilter: ((any Error) -> Bool)? = nil
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
      try await Task.sleep(for: delay)
      retry += 1
    }
  }
}
