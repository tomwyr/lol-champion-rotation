import Vapor

struct MobileUser: Content {
  let notificationsToken: String?
  let notificationsEnabled: Bool
}
