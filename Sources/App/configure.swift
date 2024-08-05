import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    let databaseUrl = Environment.get("DATABASE_URL")!
    try app.databases.use(.postgres(url: databaseUrl), as: .psql)
    app.migrations.addAppMigrations()
    // register routes
    try routes(app)
}
