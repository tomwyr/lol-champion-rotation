import Fluent
import Vapor

extension Collection {
  func associatedBy<Key>(
    key selectKey: (Element) -> Key,
    _ onDuplicate: AssociatedByDuplicatePolicy = .replace,
  ) -> [Key: Element] {
    reduce(into: [Key: Element]()) { dict, value in
      let key = selectKey(value)
      let isUpdate = dict.index(forKey: key) != nil
      if !isUpdate || onDuplicate == .replace {
        dict[key] = value
      }
    }
  }

  func associatedBy<Key, Value>(
    key selectKey: (Element) -> Key,
    value selectValue: (Element) -> Value,
    onDuplicate: AssociatedByDuplicatePolicy = .replace,
  ) -> [Key: Value] {
    reduce(into: [Key: Value]()) { dict, value in
      let key = selectKey(value)
      let isUpdate = dict.index(forKey: key) != nil
      if !isUpdate || onDuplicate == .replace {
        dict[key] = selectValue(value)
      }
    }
  }

  func associatedBy<Key>(
    key selectKey: KeyPath<Element, Key>,
    onDuplicate: AssociatedByDuplicatePolicy = .replace,
  ) -> [Key: Element] {
    reduce(into: [Key: Element]()) { dict, value in
      let key = value[keyPath: selectKey]
      let isUpdate = dict.index(forKey: key) != nil
      if !isUpdate || onDuplicate == .replace {
        dict[key] = value
      }
    }
  }

  func associatedBy<Key, Value>(
    key selectKey: KeyPath<Element, Key>,
    value selectValue: KeyPath<Element, Value>,
    onDuplicate: AssociatedByDuplicatePolicy = .replace,
  ) -> [Key: Value] {
    reduce(into: [Key: Value]()) { dict, value in
      let key = value[keyPath: selectKey]
      let isUpdate = dict.index(forKey: key) != nil
      if !isUpdate || onDuplicate == .replace {
        dict[key] = value[keyPath: selectValue]
      }
    }
  }
}

enum AssociatedByDuplicatePolicy {
  case ignore, replace
}

extension Application {
  func grouped(_ path: PathComponent..., builder: (RoutesBuilder) -> Void) {
    builder(grouped(path))
  }

  func protected(with requestGuard: RequestAuthenticatorGuard) -> RoutesBuilder {
    grouped(requestGuard)
  }

  func protected(with requestGuards: RequestAuthenticatorGuard...) -> RoutesBuilder {
    grouped(requestGuards)
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

extension Array {
  func takeUntil(_ predicate: (Element) -> Bool) -> [Element] {
    var result: [Element] = []
    for element in self {
      if predicate(element) { break }
      result.append(element)
    }
    return result
  }
}

extension Array where Element: Any {
  subscript(try index: Int) -> Element? {
    (0..<count) ~= index ? self[index] : nil
  }

  mutating func sort(by keyPath: KeyPath<Self.Element, some Comparable>) {
    sort { lhs, rhs in lhs[keyPath: keyPath] < rhs[keyPath: keyPath] }
  }

  func sorted(by keyPath: KeyPath<Self.Element, some Comparable>) -> [Element] {
    sorted { lhs, rhs in lhs[keyPath: keyPath] < rhs[keyPath: keyPath] }
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

  mutating func appendIfAbsent(_ element: Element) {
    if !contains(element) {
      append(element)
    }
  }

  mutating func removeAll(_ element: Element) {
    self.removeAll { $0 == element }
  }
}

extension Date {
  static func iso(_ string: String) -> Date? {
    ISO8601DateFormatter().date(from: string)
  }

  static func isoDate(_ string: String) -> Date? {
    ISO8601DateFormatter().date(from: "\(string)T00:00:00Z")
  }

  func adding(_ value: Int, _ component: Calendar.Component) -> Date? {
    Calendar.currentUtc.date(byAdding: component, value: value, to: self)
  }

  func trimTime() -> Date {
    Calendar.currentUtc.startOfDay(for: self)
  }

  func withTime(of other: Date) -> Date? {
    let calendar = Calendar.currentUtc
    let components = calendar.dateComponents([.hour, .minute, .second], from: other)
    guard let hour = components.hour,
      let minute = components.minute,
      let second = components.second
    else {
      return nil
    }
    return calendar.date(bySettingHour: hour, minute: minute, second: second, of: self)
  }

  func advancedToNext(weekday: Int? = nil) -> Date? {
    Calendar.currentUtc.nextDate(
      after: self,
      matching: DateComponents(weekday: weekday),
      matchingPolicy: .nextTime,
    )
  }

}

extension Calendar {
  static var currentUtc: Calendar {
    var calendar = Calendar.current
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
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
  func asyncMapSequential<T, E: Error>(
    _ mapper: (Element) async throws(E) -> T
  ) async throws(E) -> [T] {
    var results = [T]()
    for element in self {
      let result = try await mapper(element)
      results.append(result)
    }
    return results
  }
}

extension Collection {
  func asyncMap<T>(
    operation: @Sendable @escaping (Element) async throws -> T
  ) async throws -> [T] where Element: Sendable, T: Sendable {
    try await withThrowingTaskGroup(of: T.self) { group in
      for element in self {
        group.addTask { try await operation(element) }
      }
      return try await Array(group)
    }
  }

  func asyncMap<T>(
    inChunksOf chunkCount: Int,
    operation: @Sendable @escaping (Element) async throws -> T
  ) async throws -> [T] where Element: Sendable, T: Sendable {
    var results = [T]()
    for chunk in chunks(ofCount: chunkCount) {
      let chunkResults = try await chunk.asyncMap(operation: operation)
      results.append(contentsOf: chunkResults)
    }
    return results
  }
}

extension Dictionary {
  var entries: [(Key, Value)] {
    self.map { ($0, $1) }
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

extension Date {
  init?(
    year: Int? = nil, month: Int? = nil, day: Int? = nil,
    calendar: Calendar = .current,
  ) {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    guard let date = calendar.date(from: components) else {
      return nil
    }
    self = date
  }

  func distance(
    to other: Date, in component: Calendar.Component,
    calendar: Calendar = .current,
  ) -> Int? {
    calendar.dateComponents([component], from: self, to: other).value(for: component)
  }
}
