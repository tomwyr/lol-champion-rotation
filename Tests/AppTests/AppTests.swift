import Fluent
import XCTVapor

@testable import App

class AppTests: XCTestCase {
  private var testApp: Application?

  var app: Application {
    guard let testApp else {
      fatalError("The application must be initialized with configureApp before using it in a test.")
    }
    return testApp
  }

  func configureApp() async throws {
    try await testApp?.asyncShutdown()
    testApp = try await Application.make(.testing)
  }

  override func tearDown() async throws {
    try await testApp?.asyncShutdown()
  }
}

extension NotificationsConfigModel: Equatable {
  static public func == (lhs: NotificationsConfigModel, rhs: NotificationsConfigModel) -> Bool {
    lhs.userId == rhs.userId && lhs.token == rhs.token && lhs.rotationChanged == rhs.rotationChanged
      && lhs.championsAvailable == rhs.championsAvailable
  }
}

extension AppTests {
  func dbPatchVersions() async throws -> [String?] {
    try await PatchVersionModel.query(on: app.db).all().map(\.value)
  }

  func dbNotificationConfigs() async throws -> [NotificationsConfigModel] {
    try await NotificationsConfigModel.query(on: app.db).all()
  }

  func dbUserWatchlists(userId: String) async throws -> UserWatchlistsModel? {
    try await UserWatchlistsModel.query(on: app.db).filter(\.$userId == userId).first()
  }

  func dbChampions() async throws -> [ChampionModel] {
    try await ChampionModel.query(on: app.db).all()
  }

  func dbRegularRotations() async throws -> [RegularChampionRotationModel] {
    try await RegularChampionRotationModel.query(on: app.db).all()
  }
}
