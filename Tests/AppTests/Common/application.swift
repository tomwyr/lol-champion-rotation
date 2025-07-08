import VaporTesting

@testable import App

func withApp(run testBody: (Application) async throws -> Void) async throws {
  let app = try await Application.make(.testing)
  do {
    try await testBody(app)
    try await app.asyncShutdown()
  } catch {
    try await app.asyncShutdown()
    throw error
  }
}
