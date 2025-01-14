struct NotificationsService {
  let appDatabase: AppDatabase
  let pushNotificationsClient: PushNotificationsClient

  func updateToken(deviceId: String, input: NotificationsTokenInput) async throws {
    let config = try await getOrCreateConfig(deviceId)
    config.token = input.token
    try await appDatabase.updateNotificationsConfig(data: config)
  }

  func hasSettings(deviceId: String) async throws -> Bool {
    let data = try await appDatabase.getNotificationsConfig(deviceId: deviceId)
    return data != nil
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

    try await cleanupStaleTokens(configs, result)
  }

  private func cleanupStaleTokens(
    _ configs: [NotificationsConfigModel],
    _ result: SendNotificationResult
  ) async throws {
    let staleDeviceIds = configs.filter { config in
      result.staleTokens.contains(config.token)
    }.map(\.deviceId)

    if !staleDeviceIds.isEmpty {
      try await appDatabase.removeNotificationsConfigs(deviceIds: staleDeviceIds)
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
