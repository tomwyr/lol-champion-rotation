import FluentSQLiteDriver
import XCTVapor

@testable import App

extension AppTests {
  func testConfigure(deps: Dependencies) throws {
    try database(deps)
    try routes(app, deps)
  }

  func database(_ deps: Dependencies) throws {
    app.databases.use(.sqlite(.memory), as: .sqlite)
    app.migrations.addAppMigrations()
    try app.autoRevert().wait()
    try app.autoMigrate().wait()
  }

  func testConfigureWith(appManagementKey: String) throws {
    try testConfigure(
      deps: .mock(
        appConfig: .empty(appManagementKey: appManagementKey),
        httpClient: MockHttpClient(respond: mockRespond)
      )
    )
  }
}
