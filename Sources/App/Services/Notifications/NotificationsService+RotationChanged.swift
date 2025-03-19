extension NotificationsService {
  func sendRotationChanged() async throws {
    let configs = try await appDb.getCurrentRotationNotificationConfigs()
    let notification = PushNotification.rotationChanged(tokens: configs.map(\.token))
    let result = try await pushNotificationsClient.send(notification)
    try await cleanupStaleTokens(configs, [result])
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
