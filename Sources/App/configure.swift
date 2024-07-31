import Fluent
import FluentSQLiteDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    app.migrations.addAppMigrations()
    // register routes
    try routes(app)
}
