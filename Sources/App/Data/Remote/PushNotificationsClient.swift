import FCM

struct PushNotificationsClient {
  let fcm: FCM

  func send(_ notification: PushNotification) async throws -> SendNotificationResult {
    let results = try await notification.tokens.async.map { token in
      let success = await sendWithFcm(notification, token)
      return (token: token, success: success)
    }.collect()

    let failedTokens = results.filter { result in !result.success }.map(\.token)

    return SendNotificationResult(failedTokens: failedTokens)
  }

  private func sendWithFcm(_ notification: PushNotification, _ token: String) async -> Bool {
    do {
      let message = FCMMessage(
        token: token,
        notification: FCMNotification(title: notification.title, body: notification.body),
        data: notification.data
      )
      _ = try await fcm.send(message)
      return true
    } catch {
      // TODO: Catch only errors specific to when the token/device is corrupted.
      return false
    }
  }
}

struct PushNotification {
  let title: String
  let body: String
  let data: [String: String]?
  let tokens: [String]
}

struct SendNotificationResult {
  let failedTokens: [String]
}
