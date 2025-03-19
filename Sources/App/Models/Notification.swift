import Vapor

struct NotificationsTokenInput: Content {
  let token: String
}

struct NotificationsSettings: Content {
  let currentRotation: Bool
  let observedChampions: Bool

  var anyEnabled: Bool {
    currentRotation || observedChampions
  }
}
