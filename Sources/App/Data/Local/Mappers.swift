extension ChampionModel {
  convenience init(championData: ChampionData) {
    self.init(
      riotId: championData.id,
      name: championData.name,
      title: championData.title
    )
  }
}

extension Collection<ChampionData> {
  func toModels() -> [ChampionModel] {
    map { .init(championData: $0) }
  }
}

extension NotificationsConfigModel {
  func toNotificationsSettings() -> NotificationsSettings {
    .init(
      rotationChanged: rotationChanged,
      championsAvailable: championsAvailable,
      championReleased: championReleased,
    )
  }
}
