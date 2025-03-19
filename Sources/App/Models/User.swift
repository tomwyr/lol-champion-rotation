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
      if let settings {
        if settings.anyEnabled { .enabled } else { .disabled }
      } else {
        .uninitialized
      }
  }
}
