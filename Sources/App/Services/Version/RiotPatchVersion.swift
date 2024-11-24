protocol RiotPatchVersion {
  init(rawValue: String) throws

  var rawValue: String { get }

  static func newestOf(versions: [String]) -> Self?
  static func increased(from: Self, to: Self) -> Bool
}

extension String: RiotPatchVersion {
  var rawValue: String { self }

  init(rawValue: String) throws {
    self.init(rawValue)
  }

  static func newestOf(versions: [String]) -> String? {
    versions.first
  }

  static func increased(from: String, to: String) -> Bool {
    from != to
  }
}

extension SemanticVersion: RiotPatchVersion {
  var rawValue: String { self.value }

  init(rawValue: String) throws {
    try self.init(rawValue)
  }

  static func newestOf(versions: [String]) -> SemanticVersion? {
    versions.compactMap(SemanticVersion.init(try:)).latest
  }

  static func increased(from: SemanticVersion, to: SemanticVersion) -> Bool {
    to > from
  }
}
