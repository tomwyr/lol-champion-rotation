import Testing

@testable import App

@Suite struct SemanticVersionTests {
  @Test func validInitialization() throws {
    let version = try SemanticVersion("1.2.3")
    #expect(version.value == "1.2.3")
    #expect(version.major == 1)
    #expect(version.minor == 2)
    #expect(version.patch == 3)
    #expect(version.build == nil)
  }

  @Test func validInitializationWithBuild() throws {
    let version = try SemanticVersion("1.2.3+456")
    #expect(version.value == "1.2.3+456")
    #expect(version.major == 1)
    #expect(version.minor == 2)
    #expect(version.patch == 3)
    #expect(version.build == 456)
  }

  @Test func invalidFormatThrows() {
    #expect(throws: Error.self) { try SemanticVersion("invalid") }
    #expect(throws: Error.self) { try SemanticVersion("1.2") }
    #expect(throws: Error.self) { try SemanticVersion("1.2.3.4") }
    #expect(throws: Error.self) { try SemanticVersion("a.b.c") }
  }

  @Test func tryInitReturnsNilForInvalidFormat() {
    #expect(SemanticVersion(try: "invalid") == nil)
    #expect(SemanticVersion(try: "1.2") == nil)
    #expect(SemanticVersion(try: "1.2.3.4") == nil)
    #expect(SemanticVersion(try: "a.b.c") == nil)
  }

  @Test func majorVersionComparison() throws {
    let v1 = try SemanticVersion("1.0.0")
    let v2 = try SemanticVersion("2.0.0")

    #expect(v1 < v2)
    #expect(v1 <= v2)
  }

  @Test func minorVersionComparison() throws {
    let v1 = try SemanticVersion("1.0.0")
    let v2 = try SemanticVersion("1.1.0")

    #expect(v1 < v2)
    #expect(v1 <= v2)
  }

  @Test func patchVersionComparison() throws {
    let v1 = try SemanticVersion("1.0.0")
    let v2 = try SemanticVersion("1.0.1")

    #expect(v1 < v2)
    #expect(v1 <= v2)
  }

  @Test func buildVersionComparison() throws {
    let v1 = try SemanticVersion("1.0.0+1")
    let v2 = try SemanticVersion("1.0.0+2")

    #expect(v1 < v2)
    #expect(v1 <= v2)
  }

  @Test func versionWithNoBuildIsLessThanVersionWithBuild() throws {
    let v1 = try SemanticVersion("1.0.0")
    let v2 = try SemanticVersion("1.0.0+1")

    #expect(v1 < v2)
    #expect(v1 <= v2)
  }

  @Test func equalVersions() throws {
    let v1 = try SemanticVersion("1.0.0")
    let v2 = try SemanticVersion("1.0.0")

    #expect(v1 == v2)
    #expect(v1 <= v2)
    #expect(v1 >= v2)
  }

  @Test func equalVersionsWithBuild() throws {
    let v1 = try SemanticVersion("1.0.0+1")
    let v2 = try SemanticVersion("1.0.0+1")

    #expect(v1 == v2)
    #expect(v1 <= v2)
    #expect(v1 >= v2)
  }

  @Test func majorVersionGreaterThan() throws {
    let v1 = try SemanticVersion("2.0.0")
    let v2 = try SemanticVersion("1.0.0")

    #expect(v1 > v2)
    #expect(v1 >= v2)
  }

  @Test func minorVersionGreaterThan() throws {
    let v1 = try SemanticVersion("1.2.0")
    let v2 = try SemanticVersion("1.1.0")

    #expect(v1 > v2)
    #expect(v1 >= v2)
  }

  @Test func patchVersionGreaterThan() throws {
    let v1 = try SemanticVersion("1.0.2")
    let v2 = try SemanticVersion("1.0.1")

    #expect(v1 > v2)
    #expect(v1 >= v2)
  }

  @Test func buildVersionGreaterThan() throws {
    let v1 = try SemanticVersion("1.0.0+2")
    let v2 = try SemanticVersion("1.0.0+1")

    #expect(v1 > v2)
    #expect(v1 >= v2)
  }

  @Test func versionWithBuildIsGreaterThanVersionWithoutBuild() throws {
    let v1 = try SemanticVersion("1.0.0+1")
    let v2 = try SemanticVersion("1.0.0")

    #expect(v1 > v2)
    #expect(v1 >= v2)
  }

  @Test func latestVersion() throws {
    let versions = ["15.22.1", "14.27.5", "15.23.5", "15.23.0", "15.22.8"]
    let latest = try versions.map { try SemanticVersion($0) }.latest?.value

    #expect(latest == "15.23.5")
  }
}
