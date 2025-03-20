import Vapor

struct NotificationsTokenInput: Content {
  let token: String
}

struct NotificationsSettings: Content {
  let rotationChanged: Bool
  let championsAvailable: Bool

  var anyEnabled: Bool {
    rotationChanged || championsAvailable
  }
}
