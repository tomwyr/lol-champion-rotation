struct NotificationsService {
  let appDatabase: AppDatabase
  let pushNotificationsClient: PushNotificationsClient

  func updateToken(input: NotificationsTokenInput) async throws {
    let config = try await getOrCreateConfig(input.deviceId)
    config.token = input.token
    try await appDatabase.updateNotificationsConfig(data: config)
  }

  func updateSettings(input: NotificationsSettingsInput) async throws {
    let config = try await getOrCreateConfig(input.deviceId)
    config.enabled = input.enabled
    try await appDatabase.updateNotificationsConfig(data: config)
  }

  func notifyRotationChanged() async throws {
    let configs = try await appDatabase.getEnabledNotificationConfigs()

    let notification = PushNotification.rotationChanged(tokens: configs.map(\.token))
    let result = try await pushNotificationsClient.send(notification)

    let tokenFailed = { (config: NotificationsConfigModel) -> Bool in
      result.failedTokens.contains(config.token)
    }
    let corruptDeviceIds = configs.filter(tokenFailed).map(\.deviceId)
    try await appDatabase.removeNotificationsConfigs(deviceIds: corruptDeviceIds)
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
      description: "New champion rotation is now available",
      tokens: tokens
    )
  }
}
