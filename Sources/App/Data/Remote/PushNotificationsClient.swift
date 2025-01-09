class PushNotificationsClient {
  func send(_ notification: PushNotification) async throws -> SendNotificationResult {
    SendNotificationResult(failedTokens: [])
  }
}

struct PushNotification {
  let title: String
  let description: String
  let tokens: [String]
}

struct SendNotificationResult {
  let failedTokens: [String]
}
