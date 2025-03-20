import FluentSQLiteDriver
import XCTVapor

@testable import App

typealias InitDb = (Database) async throws -> Void
typealias InitDbModel<T> = (T) -> Void where T: Model

typealias AppTestsMocks = (
  httpClient: MockHttpClient,
  fcm: MockFcmDispatcher
)

extension AppTests {
  func testConfigureWith(
    appManagementKey: String? = nil,
    idHasherSeed: String? = nil,
    dbRegularRotations: [RegularChampionRotationModel] = [],
    dbBeginnerRotations: [BeginnerChampionRotationModel] = [],
    dbChampions: [ChampionModel] = [],
    dbPatchVersions: [PatchVersionModel] = [],
    dbNotificationsConfigs: [NotificationsConfigModel] = [],
    dbUserWatchlists: [UserWatchlistsModel] = [],
    b2AuthorizeDownloadData: AuthorizationData? = nil,
    riotPatchVersions: [String]? = nil,
    riotChampionRotationsData: ChampionRotationsData? = nil,
    riotChampionsData: ChampionsData? = nil,
    sendFcmMessage: SendFcmMessage? = nil
  ) async throws -> AppTestsMocks {
    let httpClient = MockHttpClient { url in
      return switch url {
      case requestUrls.riotPatchVersions:
        riotPatchVersions
      case requestUrls.riotChampionRotations:
        riotChampionRotationsData
      case let url where url.wholeMatch(of: championsDataRegex) != nil:
        riotChampionsData
      case requestUrls.b2AuthorizeDownload:
        b2AuthorizeDownloadData
      default:
        nil
      }
    }

    let fcm = MockFcmDispatcher { message in
      sendFcmMessage?(message) ?? ""
    }

    try await testConfigure(
      deps: .mock(
        appConfig: .empty(
          appManagementKey: appManagementKey ?? "",
          idHasherSeed: idHasherSeed ?? ""
        ),
        httpClient: httpClient,
        fcm: fcm
      ),
      initDb: { db async throws in
        for rotation in dbRegularRotations {
          try await rotation.create(on: db)
        }
        for rotation in dbBeginnerRotations {
          try await rotation.create(on: db)
        }
        for champion in dbChampions {
          try await champion.create(on: db)
        }
        for version in dbPatchVersions {
          let observedAt = version.observedAt
          try await version.create(on: db)
          if let observedAt {
            version.observedAt = observedAt
            try await version.update(on: db)
          }
        }
        for config in dbNotificationsConfigs {
          try await config.create(on: db)
        }
        for watchlists in dbUserWatchlists {
          try await watchlists.create(on: db)
        }
      }
    )

    return (httpClient, fcm)
  }

  func testConfigure(deps: Dependencies, initDb: InitDb) async throws {
    try await configureApp()
    try await database(deps, initDb)
    try routes(app, deps)
  }

  func database(_ deps: Dependencies, _ initDb: InitDb) async throws {
    guard let dbUrl = Environment.get("TEST_DATABASE_URL") else {
      fatalError("Database url environment variable not set.")
    }
    app.databases.use(try .postgres(url: dbUrl), as: .psql)
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
