import FluentPostgresDriver
import Vapor

func configure(_ app: Application, _ deps: Dependencies) async throws {
  try database(app, deps)
  try routes(app, deps)
  try cors(app, deps)
  try firebase(app, deps)
}

private func database(_ app: Application, _ deps: Dependencies) throws {
  try app.databases.use(.postgres(url: deps.appConfig.databaseUrl), as: .psql)
  app.migrations.addAppMigrations()
}

private func cors(_ app: Application, _ deps: Dependencies) throws {
  app.middleware.use(
    CORSMiddleware(
      configuration: .init(
        allowedOrigin: .any(deps.appConfig.appAllowedOrigins),
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
      )
    )
  )
}

private func firebase(_ app: Application, _ deps: Dependencies) throws {
  app.jwt.firebaseAuth.applicationIdentifier = deps.appConfig.firebaseProjectId
  app.fcm.configuration = .envServiceAccountKey
}
