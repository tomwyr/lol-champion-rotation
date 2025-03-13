import XCTVapor

@testable import App

class AppTests: XCTestCase {
  var app: Application!

  override func setUp() async throws {
    app = try await Application.make(.testing)
  }

  override func tearDown() async throws {
    try await app.asyncShutdown()
    app = nil
  }
}

extension NotificationsConfigModel: Equatable {
  static public func == (lhs: NotificationsConfigModel, rhs: NotificationsConfigModel) -> Bool {
    lhs.userId == rhs.userId && lhs.token == rhs.token && lhs.enabled == rhs.enabled
  }
}

extension AppTests {
  func dbPatchVersions() async throws -> [String?] {
    try await PatchVersionModel.query(on: app.db).all().map(\.value)
  }

  func dbNotificationConfigs() async throws -> [NotificationsConfigModel] {
    try await NotificationsConfigModel.query(on: app.db).all()
  }
}
