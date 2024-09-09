import FluentPostgresDriver
import Vapor

func configure(_ app: Application, _ deps: Dependencies) async throws {
    try database(app, deps)
    try routes(app, deps)
    try files(app)
}

private func database(_ app: Application, _ deps: Dependencies) throws {
    try app.databases.use(.postgres(url: deps.appConfig.databaseUrl), as: .psql)
    app.migrations.addAppMigrations()
}

private func routes(_ app: Application, _ deps: Dependencies) throws {
    try apiRoutes(app, deps)
    try clientRoutes(app)
}

private func files(_ app: Application) throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
}
