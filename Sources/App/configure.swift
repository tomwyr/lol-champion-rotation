import FluentPostgresDriver
import Vapor

func configure(_ app: Application, _ deps: Dependencies) async throws {
  try database(app, deps)
  routes(app, deps)
  cors(app, deps)
  // Configure error handling after CORS to prevent the behavior of missing
  // response headers when responding with non-ok status (e.g. 404).
  errorHandler(app, deps)
  logger(app, deps)
  firebase(app, deps)
}

private func database(_ app: Application, _ deps: Dependencies) throws {
  try app.databases.use(
    .postgres(
      url: deps.appConfig.databaseUrl,
      connectionPoolTimeout: .seconds(15),
    ), as: .psql)
  app.migrations.addAppMigrations()
}

private func cors(_ app: Application, _ deps: Dependencies) {
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

private func errorHandler(_ app: Application, _ deps: Dependencies) {
  app.middleware.use(ErrorMiddleware.default(environment: app.environment))
}

private func logger(_ app: Application, _ deps: Dependencies) {
  app.middleware.use(RouteLoggingMiddleware())
}

private func firebase(_ app: Application, _ deps: Dependencies) {
  app.jwt.firebaseAuth.applicationIdentifier = deps.appConfig.firebaseProjectId
  app.fcm.configuration = .envServiceAccountKey
}
