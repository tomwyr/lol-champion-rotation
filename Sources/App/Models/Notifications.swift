import Vapor

struct NotificationsTokenInput: Content {
  let deviceId: String
  let token: String
}

struct NotificationsSettingsInput: Content {
  let deviceId: String
  let enabled: Bool
}
