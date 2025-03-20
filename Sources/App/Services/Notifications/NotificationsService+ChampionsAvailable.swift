extension NotificationsService {
  func notifyChampionsAvailable() async throws {
    let localData = try await loadLocalData()
    let notificationsData = resolveNotificationsData(localData)
    try await sendNotifications(localData, notificationsData)
  }

  private func loadLocalData() async throws -> LocalData {
    guard let rotation = try await appDb.currentRegularRotation() else {
      throw NotificationsError.currentRotationUnavailable
    }
    let configs = try await appDb.getChampionsAvailableNotificationConfigs()
    let champions = try await appDb.champions(riotIds: rotation.champions)
    let userWatchlists = try await appDb.userWatchlists(userIds: configs.map(\.userId))
    return (configs, champions, userWatchlists)
  }

  private func resolveNotificationsData(_ localData: LocalData) -> [NotificationData] {
    // TODO id -> riotId
    let championsById = localData.champions.associatedBy(\.idString)
    let watchlistsByUserId = localData.userWatchlists.associatedBy(\.userId)

    var configsByChampions = [[String]: [NotificationsConfigModel]]()
    for config in localData.configs {
      guard let watchlist = watchlistsByUserId[config.userId] else {
        continue
      }
      let champions = watchlist.champions
        .compactMap { championsById[$0]?.name }
        .sorted()
      if !champions.isEmpty {
        configsByChampions[champions, default: []].append(config)
      }
    }

    return configsByChampions.entries
  }

  private func sendNotifications(
    _ localData: LocalData,
    _ notificationsData: [NotificationData]
  ) async throws {
    let results = try await notificationsData.asyncMap(inChunksOf: 5) { (champions, configs) in
      let tokens = configs.map(\.token)
      let notification = PushNotification.championsAvailable(tokens: tokens, champions: champions)
      return try await pushNotificationsClient.send(notification)
    }
    try await cleanupStaleTokens(localData.configs, results)
  }
}

extension PushNotification {
  static func championsAvailable(tokens: [String], champions: [String]) -> PushNotification {
    let title =
      if champions.count == 1 {
        "Champion Available"
      } else {
        "Champions Available"
      }

    let body =
      switch champions.count {
      case 0: ""
      case 1: "\(champions[0]) is now available in the rotation"
      case 2: "\(champions[0]) and \(champions[1]) are now available in the rotation"
      default:
        "\(champions[0]), \(champions[1]) and \(champions.count - 2) more are now available in the rotation"
      }

    return PushNotification(
      title: title,
      body: body,
      data: ["type": "championsAvailable"],
      tokens: tokens
    )
  }
}

private typealias LocalData = (
  configs: [NotificationsConfigModel],
  champions: [ChampionModel],
  userWatchlists: [UserWatchlistsModel]
)

private typealias NotificationData = (
  champions: [String],
  configs: [NotificationsConfigModel]
)
