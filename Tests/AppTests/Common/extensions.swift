import Foundation

@testable import App

extension ChampionModel {
  convenience init(id: UUID?, releasedAt: Date? = nil, riotId: String, name: String) {
    self.init(id: id, releasedAt: releasedAt, riotId: riotId, name: name, title: "")
  }
}

extension ChampionData {
  init(id: String, key: String, name: String) {
    self.init(id: id, key: key, name: name, title: "")
  }
}
