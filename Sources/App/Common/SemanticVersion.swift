struct SemanticVersion: Comparable {
  let value: String
  let major: Int
  let minor: Int
  let patch: Int
  let build: Int?

  init?(try value: String) {
    do {
      try self.init(value)
    } catch {
      return nil
    }
  }

  init(_ value: String) throws {
    let formatError = SemanticVersionError.invalidFormat(value)

    func toInt(_ text: Substring) throws -> Int {
      guard let result = Int(text) else { throw formatError }
      return result
    }

    let regex = #/(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?/#
    guard let result = try regex.wholeMatch(in: value) else { throw formatError }
    let (_, major, minor, patch, build) = result.output

    self.value = value
    self.major = try toInt(major)
    self.minor = try toInt(minor)
    self.patch = try toInt(patch)
    self.build = if let build { try toInt(build) } else { nil }
  }

  static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
    return if lhs.major != rhs.major {
      lhs.major < rhs.major
    } else if lhs.minor != rhs.minor {
      lhs.minor < rhs.minor
    } else if lhs.patch != rhs.patch {
      lhs.patch < rhs.patch
    } else if let lhsBuild = lhs.build, let rhsBuild = rhs.build {
      lhsBuild < rhsBuild
    } else {
      lhs.build == nil && rhs.build != nil
    }
  }
}

extension [SemanticVersion] {
  var newest: SemanticVersion? {
    sorted(by: >).first
  }
}

enum SemanticVersionError: Error {
  case invalidFormat(_ value: String)
}
