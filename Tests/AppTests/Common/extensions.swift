import Fluent
import Foundation
import VaporTesting

@testable import App

extension ChampionModel {
  convenience init(id: UUID?, releasedAt: Date? = nil, riotId: String = "", name: String = "") {
    self.init(id: id, releasedAt: releasedAt, riotId: riotId, name: name, title: "")
  }
}

extension ChampionData {
  init(id: String, key: String, name: String) {
    self.init(id: id, key: key, name: name, title: "")
  }
}

extension RegularChampionRotationModel {
  convenience init(id: UUID?, active: Bool = true, slug: String) {
    self.init(id: id, active: active, observedAt: Date.now, champions: [], slug: slug)
  }
}

extension NotificationsConfigModel: Equatable {
  static public func == (lhs: NotificationsConfigModel, rhs: NotificationsConfigModel) -> Bool {
    lhs.userId == rhs.userId && lhs.token == rhs.token
      && lhs.rotationChanged == rhs.rotationChanged
      && lhs.championsAvailable == rhs.championsAvailable
      && lhs.championReleased == rhs.championReleased
  }
}

extension AppConfig {
  static func empty(
    databaseUrl: String = "",
    appAllowedOrigins: [String] = [],
    appManagementKey: String = "",
    b2AppKeyId: String = "",
    b2AppKeySecret: String = "",
    riotApiKey: String = "",
    idHasherSeed: String = "",
    firebaseProjectId: String = "",
    linearAccessToken: String = "",
    linearTeamId: String = "",
    linearFeedbackStateId: String = "",
  ) -> AppConfig {
    .init(
      databaseUrl: databaseUrl,
      appAllowedOrigins: appAllowedOrigins,
      appManagementKey: appManagementKey,
      b2AppKeyId: b2AppKeyId,
      b2AppKeySecret: b2AppKeySecret,
      riotApiKey: riotApiKey,
      idHasherSeed: idHasherSeed,
      firebaseProjectId: firebaseProjectId,
      linearAccessToken: linearAccessToken,
      linearTeamId: linearTeamId,
      linearFeedbackStateId: linearFeedbackStateId,
    )
  }
}

extension Application {
  func dbPatchVersions() async throws -> [String?] {
    try await PatchVersionModel.query(on: db).all().map(\.value)
  }

  func dbNotificationConfigs() async throws -> [NotificationsConfigModel] {
    try await NotificationsConfigModel.query(on: db).all()
  }

  func dbUserWatchlists(userId: String) async throws -> UserWatchlistsModel? {
    try await UserWatchlistsModel.query(on: db).filter(\.$userId == userId).first()
  }

  func dbChampions() async throws -> [ChampionModel] {
    try await ChampionModel.query(on: db).all()
  }

  func dbRegularRotations() async throws -> [RegularChampionRotationModel] {
    try await RegularChampionRotationModel.query(on: db).all()
  }

  func dbRotationSlugs() async throws -> [String] {
    try await RegularChampionRotationModel.query(on: db).all().map(\.slug)
  }

  func dbRotationPredictions() async throws -> [ChampionRotationPredictionModel] {
    try await ChampionRotationPredictionModel.query(on: db).all()
  }
}
