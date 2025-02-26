import Foundation

@testable import App

extension ChampionModel {
  convenience init(id: UUID?, riotId: String, name: String) {
    self.init(id: id, riotId: riotId, name: name, title: "")
  }
}

extension ChampionData {
  init(id: String, key: String, name: String) {
    self.init(id: id, key: key, name: name, title: "")
  }
}
