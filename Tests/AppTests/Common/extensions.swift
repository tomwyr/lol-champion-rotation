import Foundation

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
  convenience init(id: UUID?, slug: String) {
    self.init(id: id, observedAt: Date.now, champions: [], slug: slug)
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
    firebaseProjectId: String = ""
  ) -> AppConfig {
    .init(
      databaseUrl: databaseUrl,
      appAllowedOrigins: appAllowedOrigins,
      appManagementKey: appManagementKey,
      b2AppKeyId: b2AppKeyId,
      b2AppKeySecret: b2AppKeySecret,
      riotApiKey: riotApiKey,
      idHasherSeed: idHasherSeed,
      firebaseProjectId: firebaseProjectId
    )
  }
}
