import Vapor

extension MutableCollection {
  func associateBy<Key>(_ selector: KeyPath<Element, Key>) -> [Key: Element] {
    reduce(into: [Key: Element]()) { dict, value in
      dict[value[keyPath: selector]] = value
    }
  }
}

extension Application {
  func grouped(_ path: PathComponent..., builder: (RoutesBuilder) -> Void) {
    builder(grouped(path))
  }

  func protected(with requestGuard: RequestAuthenticatorGuard) -> RoutesBuilder {
    grouped(requestGuard)
  }
}

extension RoutesBuilder {
  func grouped(_ path: PathComponent..., builder: (RoutesBuilder) -> Void) {
    builder(grouped(path))
  }

  func protected(with requestGuard: RequestAuthenticatorGuard) -> RoutesBuilder {
    grouped(requestGuard)
  }
}

extension Array where Element: Any {
  subscript(try index: Int) -> Element? {
    (0..<count) ~= index ? self[index] : nil
  }
}

extension Array where Element: Hashable {
  func uniqued() -> [Element] {
    Array(Set(self))
  }
}

extension Date {
  static func iso(_ string: String) -> Date? {
    ISO8601DateFormatter().date(from: string)
  }

  func adding(_ value: Int, _ component: Calendar.Component) -> Date? {
    Calendar.current.date(byAdding: component, value: value, to: self)
  }
}

extension String {
  subscript(range: Range<Int>) -> String {
    let safeRange = max(0, range.startIndex)..<min(count, range.endIndex)
    let start = index(startIndex, offsetBy: safeRange.startIndex)
    let end = index(startIndex, offsetBy: safeRange.endIndex)
    return String(self[start..<end])
  }

  func split(separator: Character) -> [String] {
    // Pass maxSplits to avoid method ambiguity.
    split(separator: separator, maxSplits: Int.max).map(String.init)
  }
}

extension AsyncMapSequence {
  func collect() async throws -> [Element] {
    try await Array(self)
  }
}

extension UUID {
  init(unsafe uuidString: String) throws {
    guard let result = UUID(uuidString) else {
      throw UUIDError.invalidValue(uuidString)
    }
    self = result
  }
}

enum UUIDError: Error {
  case invalidValue(_ value: String)
}
