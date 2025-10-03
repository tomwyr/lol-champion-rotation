import FluentSQLiteDriver
import VaporTesting

@testable import App

typealias InitDb = (Database) async throws -> Void

typealias AppTestsMocks = (
  httpClient: MockHttpClient,
  fcm: MockFcmDispatcher,
  rotationForecast: SpyRotationForecast
)

extension Application {
  func testConfigureWith(
    appManagementKey: String? = nil,
    idHasherSeed: String? = nil,
    dbRegularRotations: [RegularChampionRotationModel] = [],
    dbBeginnerRotations: [BeginnerChampionRotationModel] = [],
    dbRotationPredictions: [ChampionRotationPredictionModel] = [],
    dbChampions: [ChampionModel] = [],
    dbPatchVersions: [PatchVersionModel] = [],
    dbNotificationsConfigs: [NotificationsConfigModel] = [],
    dbUserWatchlists: [UserWatchlistsModel] = [],
    b2AuthorizeDownloadData: AuthorizationData? = nil,
    riotPatchVersions: [String]? = nil,
    riotChampionRotationsData: ChampionRotationsData? = nil,
    riotChampionsData: ChampionsData? = nil,
    sendFcmMessage: SendFcmMessage? = nil,
    getCurrentDate: GetDate? = nil,
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

    let rotationForecast = SpyRotationForecast()

    let instant = MockInstant(getCurrentDate: getCurrentDate)

    try await testConfigure(
      deps: .mock(
        appConfig: .empty(
          appManagementKey: appManagementKey ?? "",
          idHasherSeed: idHasherSeed ?? ""
        ),
        httpClient: httpClient,
        fcm: fcm,
        rotationForecast: rotationForecast,
        instant: instant,
      ),
      initDb: { db async throws in
        for rotation in dbRegularRotations {
          try await rotation.create(on: db)
        }
        for rotation in dbBeginnerRotations {
          try await rotation.create(on: db)
        }
        for prediction in dbRotationPredictions {
          try await prediction.create(on: db)
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

    return (httpClient, fcm, rotationForecast)
  }

  private func testConfigure(deps: Dependencies, initDb: InitDb) async throws {
    try await database(deps, initDb)
    try routes(deps)
  }

  private func routes(_ deps: Dependencies) throws {
    try App.routes(self, deps)
  }

  private func database(_ deps: Dependencies, _ initDb: InitDb) async throws {
    guard let dbUrl = Environment.get("TEST_DATABASE_URL") else {
      fatalError("Database url environment variable not set.")
    }
    databases.use(try .postgres(url: dbUrl), as: .psql)
    migrations.addAppMigrations()
    try await autoRevert()
    try await autoMigrate()
    try await initDb(db)
  }
}
