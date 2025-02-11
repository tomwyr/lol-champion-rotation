import Vapor

struct MobileUser: Content {
  let notificationsStatus: UserNotificationsStatus
}

enum UserNotificationsStatus: String, Content {
  case uninitialized = "uninitialized"
  case disabled = "disabled"
  case enabled = "enabled"

  init(from settings: NotificationsSettings?) {
    self =
      switch settings?.enabled {
      case nil: .uninitialized
      case .some(true): .enabled
      case .some(false): .disabled
      }
  }
}
