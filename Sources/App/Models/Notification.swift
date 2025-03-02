import Vapor

struct NotificationsTokenInput: Content {
  let token: String
}

struct NotificationsSettings: Content {
  let enabled: Bool
}
