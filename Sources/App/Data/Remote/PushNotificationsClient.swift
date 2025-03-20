import FCM

struct PushNotificationsClient {
  let fcm: FcmDispatcher

  func send(_ notification: PushNotification) async throws -> SendNotificationResult {
    let results = try await notification.tokens.async.map { token in
      let status = await sendWithFcm(notification, token)
      return (token: token, status: status)
    }.collect()

    let staleTokens = results.filter { result in result.status == .staleToken }.map(\.token)

    return SendNotificationResult(staleTokens: staleTokens)
  }

  private func sendWithFcm(_ notification: PushNotification, _ token: String) async -> FcmSendStatus
  {
    do {
      let message = FCMMessage(
        token: token,
        notification: FCMNotification(title: notification.title, body: notification.body),
        data: notification.data
      )
      _ = try await fcm.send(message)
      return .success
    } catch {
      return error.isStaleTokenError ? .staleToken : .otherError
    }
  }
}

extension Error {
  // Detect stale tokens according to the documentation.
  // https://firebase.google.com/docs/cloud-messaging/manage-tokens
  var isStaleTokenError: Bool {
    if let error = self as? GoogleError, let code = error.fcmError?.errorCode {
      code == .invalid || code == .unregistered
    } else {
      false
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
  let staleTokens: [String]
}

enum FcmSendStatus {
  case success, staleToken, otherError
}

protocol FcmDispatcher: Sendable {
  func send(_ message: FCMMessageDefault) async throws -> String
}

extension FCM: FcmDispatcher {}
