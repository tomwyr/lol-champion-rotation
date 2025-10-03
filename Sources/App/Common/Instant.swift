import Foundation

protocol Instant: Sendable {
  var now: Date { get }
}

extension Instant where Self == SystemInstant {
  static var system: Self { Self() }
}

struct SystemInstant: Instant {
  static var system: Self { Self() }
  var now: Date { Date.now }
}
