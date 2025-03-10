import Fluent
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

  func sorted(byComparable comparableOf: (Element) -> (some Comparable)?) -> [Element] {
    return map { element in
      (element: element, comparable: comparableOf(element))
    }
    .sorted(by: { lhs, rhs in
      guard let right = rhs.comparable else { return true }
      guard let left = lhs.comparable else { return false }
      return left < right
    })
    .map(\.element)
  }

  func zipAdjacent() -> [(Element, Element)] {
    windows(ofCount: 2).map { window in
      (window[window.startIndex], window[window.startIndex + 1])
    }
  }
}

extension Array where Element: Hashable & Comparable {
  func mostFrequent(using generator: inout some RandomNumberGenerator) -> Element? {
    var counts = [Element: Int]()
    for element in self {
      counts[element, default: 0] += 1
    }
    let maxKeys = counts.max(count: Int.max, sortedBy: { lhs, rhs in lhs.value > rhs.value })
      .map(\.key).sorted()
    return maxKeys.randomElement(using: &generator)
  }
}

extension Date {
  static func iso(_ string: String) -> Date? {
    ISO8601DateFormatter().date(from: string)
  }

  func adding(_ value: Int, _ component: Calendar.Component) -> Date? {
    Calendar.current.date(byAdding: component, value: value, to: self)
  }

  func trimTime() -> Date {
    Calendar.current.startOfDay(for: self)
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

extension Sequence {
  func asyncMap<T, E: Error>(_ mapper: (Element) async throws(E) -> T) async throws(E) -> [T] {
    var results = [T]()
    for element in self {
      let result = try await mapper(element)
      results.append(result)
    }
    return results
  }
}

extension Dictionary where Key: Comparable {
  func sorted(by keyPath: KeyPath<Self.Element, some Comparable>) -> [(Key, Value)] {
    sorted { lhs, rhs in lhs[keyPath: keyPath] < rhs[keyPath: keyPath] }
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

extension Model where IDValue == UUID {
  var idString: String? {
    id?.uuidString
  }
}
