import FluentSQLiteDriver
import XCTVapor

@testable import App

typealias InitDb = (Database) async throws -> Void
typealias InitDbModel<T> = (T) -> Void where T: Model

extension AppTests {
  func testConfigureWith(
    appManagementKey: String? = nil,
    dbChampionRotation: InitDbModel<ChampionRotationModel>? = nil,
    b2AuthorizeDownloadData: AuthorizationData? = nil,
    riotChampionRotationsData: ChampionRotationsData? = nil,
    riotChampionsData: ChampionsData? = nil
  ) async throws {
    try await testConfigure(
      deps: .mock(
        appConfig: .empty(appManagementKey: appManagementKey ?? ""),
        httpClient: MockHttpClient(respond: { url in
          switch url {
          case requestUrls.riotChampionRotations:
            riotChampionRotationsData
          case requestUrls.riotChampions:
            riotChampionsData
          case requestUrls.b2AuthorizeDownload:
            b2AuthorizeDownloadData
          default:
            nil
          }
        })
      ),
      initDb: { db async throws in
        if let initModel = dbChampionRotation {
          try await ChampionRotationModel.create(with: initModel, on: db)
        }
      }
    )
  }

  func testConfigure(deps: Dependencies, initDb: InitDb) async throws {
    try await database(deps, initDb)
    try routes(app, deps)
  }

  func database(_ deps: Dependencies, _ initDb: InitDb) async throws {
    app.databases.use(.sqlite(.memory), as: .sqlite)
    app.migrations.addAppMigrations()
    try await app.autoRevert()
    try await app.autoMigrate()
    try await initDb(app.db)
  }
}

extension Model {
  static func create(with initModel: InitDbModel<Self>, on database: Database) async throws {
    let model = Self()
    initModel(model)
    try await model.create(on: database)
  }
}
