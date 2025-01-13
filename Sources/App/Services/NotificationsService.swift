struct NotificationsService {
  let appDatabase: AppDatabase
  let pushNotificationsClient: PushNotificationsClient

  func updateToken(deviceId: String, input: NotificationsTokenInput) async throws {
    let config = try await getOrCreateConfig(deviceId)
    config.token = input.token
    try await appDatabase.updateNotificationsConfig(data: config)
  }

  func getSettings(deviceId: String) async throws -> NotificationsSettings? {
    guard let data = try await appDatabase.getNotificationsConfig(deviceId: deviceId) else {
      return nil
    }
    return NotificationsSettings(enabled: data.enabled)
  }

  func updateSettings(deviceId: String, input: NotificationsSettings) async throws {
    let config = try await getOrCreateConfig(deviceId)
    config.enabled = input.enabled
    try await appDatabase.updateNotificationsConfig(data: config)
  }

  func notifyRotationChanged() async throws {
    let configs = try await appDatabase.getEnabledNotificationConfigs()

    let notification = PushNotification.rotationChanged(tokens: configs.map(\.token))
    let result = try await pushNotificationsClient.send(notification)

    try await cleanupFailingTokens(configs, result)
  }

  private func cleanupFailingTokens(
    _ configs: [NotificationsConfigModel],
    _ result: SendNotificationResult
  ) async throws {
    let tokenFailed = { (config: NotificationsConfigModel) -> Bool in
      result.failedTokens.contains(config.token)
    }
    let corruptDeviceIds = configs.filter(tokenFailed).map(\.deviceId)
    if !corruptDeviceIds.isEmpty {
      try await appDatabase.removeNotificationsConfigs(deviceIds: corruptDeviceIds)
    }
  }

  private func getOrCreateConfig(_ deviceId: String) async throws -> NotificationsConfigModel {
    try await appDatabase.getNotificationsConfig(deviceId: deviceId)
      ?? .init(deviceId: deviceId, token: "", enabled: false)
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
