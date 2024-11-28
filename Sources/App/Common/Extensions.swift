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
  func protected(with requestGuard: RequestAuthenticatorGuard) -> RoutesBuilder {
    grouped(requestGuard)
  }
}

extension Array where Element: Any {
  subscript(try index: Int) -> Element? {
    count >= index ? self[index] : nil
  }
}

extension Array where Element: Hashable {
  func uniqued() -> [Element] {
    Array(Set(self))
  }
}
