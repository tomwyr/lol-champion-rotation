extension NotificationsService {
  func notifyChampionReleased(championId: String) async throws {
    let (configs, champion) = try await loadLocalData(championId)
    let notification = PushNotification.championReleased(
      tokens: configs.map(\.token),
      champion: champion,
    )
    let result = try await pushNotificationsClient.send(notification)
    try await cleanupStaleTokens(configs, [result])
  }

  private func loadLocalData(_ championId: String) async throws -> LocalData {
    let configs = try await appDb.getChampionReleasedNotificationConfigs()
    guard let champion = try await appDb.champion(riotId: championId) else {
      throw NotificationsError.unknownChampion(championId: championId)
    }
    return (configs, champion)
  }
}

extension PushNotification {
  static func championReleased(tokens: [String], champion: ChampionModel) -> PushNotification {
    PushNotification(
      title: "Champion released",
      body: "\(champion.name) is now available in the champion pool",
      data: ["type": "championReleased", "championId": champion.riotId],
      tokens: tokens
    )
  }
}

private typealias LocalData = (
  configs: [NotificationsConfigModel],
  champion: ChampionModel,
)
