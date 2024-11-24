import FluentSQLiteDriver
import XCTVapor

@testable import App

typealias InitDb = (Database) async throws -> Void
typealias InitDbModel<T> = (T) -> Void where T: Model

extension AppTests {
  func testConfigureWith(
    appManagementKey: String? = nil,
    dbChampionRotation: ChampionRotationModel? = nil,
    dbChampions: [ChampionModel] = [],
    dbPatchVersions: [PatchVersionModel] = [],
    b2AuthorizeDownloadData: AuthorizationData? = nil,
    riotPatchVersions: [String]? = nil,
    riotChampionRotationsData: ChampionRotationsData? = nil,
    riotChampionsData: ChampionsData? = nil,
    riotChampionsDataVersion: String? = nil
  ) async throws -> MockHttpClient {
    let httpClient = MockHttpClient(respond: { url in
      return switch url {
      case requestUrls.riotPatchVersions:
        riotPatchVersions
      case requestUrls.riotChampionRotations:
        riotChampionRotationsData
      case requestUrls.riotChampions(riotChampionsDataVersion ?? defaultPatchVersion):
        riotChampionsData
      case requestUrls.b2AuthorizeDownload:
        b2AuthorizeDownloadData
      default:
        nil
      }
    })

    try await testConfigure(
      deps: .mock(
        appConfig: .empty(appManagementKey: appManagementKey ?? ""),
        httpClient: httpClient
      ),
      initDb: { db async throws in
        if let initRotation = dbChampionRotation {
          try await initRotation.create(on: db)
        }
        for champion in dbChampions {
          try await champion.create(on: db)
        }
        for version in dbPatchVersions {
          try await version.create(on: db)
        }
      }
    )

    return httpClient
  }

  func testConfigure(deps: Dependencies, initDb: InitDb) async throws {
    try await database(deps, initDb)
    try apiRoutes(app, deps)
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
