struct NotificationsService {
  let appDb: AppDatabase
  let pushNotificationsClient: PushNotificationsClient

  func updateToken(userId: String, input: NotificationsTokenInput) async throws {
    let config = try await getOrCreateConfig(userId)
    config.token = input.token
    try await appDb.updateNotificationsConfig(data: config)
  }

  func hasSettings(userId: String) async throws -> Bool {
    let data = try await appDb.getNotificationsConfig(userId: userId)
    return data != nil
  }

  func getSettings(userId: String) async throws -> NotificationsSettings? {
    guard let data = try await appDb.getNotificationsConfig(userId: userId) else {
      return nil
    }
    return NotificationsSettings(
      rotationChanged: data.rotationChanged,
      championsAvailable: data.championsAvailable,
      championReleased: data.championReleased,
    )
  }

  func updateSettings(userId: String, input: NotificationsSettings) async throws {
    let config = try await getOrCreateConfig(userId)
    config.rotationChanged = input.rotationChanged
    config.championsAvailable = input.championsAvailable
    config.championReleased = input.championReleased
    try await appDb.updateNotificationsConfig(data: config)
  }

  func onChampionsAdded(championIds: [String]) async throws {
    for championId in championIds {
      try await notifyChampionReleased(championId: championId)
    }
  }

  func onRotationChanged() async throws {
    try await notifyRotationChanged()
    try await notifyChampionsAvailable()
  }

  func cleanupStaleTokens(
    _ configs: [NotificationsConfigModel],
    _ results: [SendNotificationResult]
  ) async throws {
    let staleTokens = Set(results.flatMap(\.staleTokens))
    let staleUserIds = configs.filter { config in
      staleTokens.contains(config.token)
    }.map(\.userId)

    if !staleUserIds.isEmpty {
      try await appDb.removeNotificationsConfigs(userIds: staleUserIds)
    }
  }

  private func getOrCreateConfig(_ userId: String) async throws -> NotificationsConfigModel {
    if let config = try await appDb.getNotificationsConfig(userId: userId) {
      return config
    }

    return .init(
      userId: userId, token: "",
      rotationChanged: false,
      championsAvailable: false,
      championReleased: false,
    )
  }
}

enum NotificationsError: Error {
  case currentRotationUnavailable
  case unknownChampion(championId: String)
}
