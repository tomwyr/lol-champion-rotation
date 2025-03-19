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
      currentRotation: data.currentRotation,
      observedChampions: data.observedChampions
    )
  }

  func updateSettings(userId: String, input: NotificationsSettings) async throws {
    let config = try await getOrCreateConfig(userId)
    config.currentRotation = input.currentRotation
    config.observedChampions = input.observedChampions
    try await appDb.updateNotificationsConfig(data: config)
  }

  func notifyRotationChanged() async throws {
    let configs = try await appDb.getNotificationConfigsWithCurrentRotation()

    let notification = PushNotification.rotationChanged(tokens: configs.map(\.token))
    let result = try await pushNotificationsClient.send(notification)

    try await cleanupStaleTokens(configs, result)
  }

  private func cleanupStaleTokens(
    _ configs: [NotificationsConfigModel],
    _ result: SendNotificationResult
  ) async throws {
    let staleUserIds = configs.filter { config in
      result.staleTokens.contains(config.token)
    }.map(\.userId)

    if !staleUserIds.isEmpty {
      try await appDb.removeNotificationsConfigs(userIds: staleUserIds)
    }
  }

  private func getOrCreateConfig(_ userId: String) async throws -> NotificationsConfigModel {
    try await appDb.getNotificationsConfig(userId: userId)
      ?? .init(userId: userId, token: "", currentRotation: false, observedChampions: false)
  }
}

extension PushNotification {
  static func rotationChanged(tokens: [String]) -> PushNotification {
    PushNotification(
      title: "Rotation Changed",
      body: "New champion rotation is now available",
      data: ["type": "rotationChanged"],
      tokens: tokens
    )
  }
}
