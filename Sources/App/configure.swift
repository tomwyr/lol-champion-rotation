import FluentPostgresDriver
import Vapor

func configure(_ app: Application, _ deps: Dependencies) async throws {
    try database(app, deps)
    try routes(app, deps)
}

private func database(_ app: Application, _ deps: Dependencies) throws {
    try app.databases.use(.postgres(url: deps.appConfig.databaseUrl), as: .psql)
    app.migrations.addAppMigrations()
}
