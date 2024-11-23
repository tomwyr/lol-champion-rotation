import XCTest

@testable import App

final class SemanticVersionTests: XCTestCase {
  func testValidInitialization() throws {
    let version = try SemanticVersion("1.2.3")
    XCTAssertEqual(version.value, "1.2.3")
    XCTAssertEqual(version.major, 1)
    XCTAssertEqual(version.minor, 2)
    XCTAssertEqual(version.patch, 3)
    XCTAssertNil(version.build)
  }

  func testValidInitializationWithBuild() throws {
    let version = try SemanticVersion("1.2.3+456")
    XCTAssertEqual(version.value, "1.2.3+456")
    XCTAssertEqual(version.major, 1)
    XCTAssertEqual(version.minor, 2)
    XCTAssertEqual(version.patch, 3)
    XCTAssertEqual(version.build, 456)
  }

  func testInvalidFormatThrows() {
    XCTAssertThrowsError(try SemanticVersion("invalid"))
    XCTAssertThrowsError(try SemanticVersion("1.2"))
    XCTAssertThrowsError(try SemanticVersion("1.2.3.4"))
    XCTAssertThrowsError(try SemanticVersion("a.b.c"))
  }

  func testTryInitReturnsNilForInvalidFormat() {
    XCTAssertNil(SemanticVersion(try: "invalid"))
    XCTAssertNil(SemanticVersion(try: "1.2"))
    XCTAssertNil(SemanticVersion(try: "1.2.3.4"))
    XCTAssertNil(SemanticVersion(try: "a.b.c"))
  }

  func testMajorVersionComparison() throws {
    let v1 = try SemanticVersion("1.0.0")
    let v2 = try SemanticVersion("2.0.0")

    XCTAssertTrue(v1 < v2)
    XCTAssertTrue(v1 <= v2)
  }

  func testMinorVersionComparison() throws {
    let v1 = try SemanticVersion("1.0.0")
    let v2 = try SemanticVersion("1.1.0")

    XCTAssertTrue(v1 < v2)
    XCTAssertTrue(v1 <= v2)
  }

  func testPatchVersionComparison() throws {
    let v1 = try SemanticVersion("1.0.0")
    let v2 = try SemanticVersion("1.0.1")

    XCTAssertTrue(v1 < v2)
    XCTAssertTrue(v1 <= v2)
  }

  func testBuildVersionComparison() throws {
    let v1 = try SemanticVersion("1.0.0+1")
    let v2 = try SemanticVersion("1.0.0+2")

    XCTAssertTrue(v1 < v2)
    XCTAssertTrue(v1 <= v2)
  }

  func testVersionWithNoBuildIsLessThanVersionWithBuild() throws {
    let v1 = try SemanticVersion("1.0.0")
    let v2 = try SemanticVersion("1.0.0+1")

    XCTAssertTrue(v1 < v2)
    XCTAssertTrue(v1 <= v2)
  }

  func testEqualVersions() throws {
    let v1 = try SemanticVersion("1.0.0")
    let v2 = try SemanticVersion("1.0.0")

    XCTAssertTrue(v1 == v2)
    XCTAssertTrue(v1 <= v2)
    XCTAssertTrue(v1 >= v2)
  }

  func testEqualVersionsWithBuild() throws {
    let v1 = try SemanticVersion("1.0.0+1")
    let v2 = try SemanticVersion("1.0.0+1")

    XCTAssertTrue(v1 == v2)
    XCTAssertTrue(v1 <= v2)
    XCTAssertTrue(v1 >= v2)
  }

  func testMajorVersionGreaterThan() throws {
    let v1 = try SemanticVersion("2.0.0")
    let v2 = try SemanticVersion("1.0.0")

    XCTAssertTrue(v1 > v2)
    XCTAssertTrue(v1 >= v2)
  }

  func testMinorVersionGreaterThan() throws {
    let v1 = try SemanticVersion("1.2.0")
    let v2 = try SemanticVersion("1.1.0")

    XCTAssertTrue(v1 > v2)
    XCTAssertTrue(v1 >= v2)
  }

  func testPatchVersionGreaterThan() throws {
    let v1 = try SemanticVersion("1.0.2")
    let v2 = try SemanticVersion("1.0.1")

    XCTAssertTrue(v1 > v2)
    XCTAssertTrue(v1 >= v2)
  }

  func testBuildVersionGreaterThan() throws {
    let v1 = try SemanticVersion("1.0.0+2")
    let v2 = try SemanticVersion("1.0.0+1")

    XCTAssertTrue(v1 > v2)
    XCTAssertTrue(v1 >= v2)
  }

  func testVersionWithBuildIsGreaterThanVersionWithoutBuild() throws {
    let v1 = try SemanticVersion("1.0.0+1")
    let v2 = try SemanticVersion("1.0.0")

    XCTAssertTrue(v1 > v2)
    XCTAssertTrue(v1 >= v2)
  }

  func testNewestVersion() throws {
    let versions = ["15.22.1", "14.27.5", "15.23.5", "15.23.0", "15.22.8"]
    let newest = try versions.map { try SemanticVersion($0) }.newest?.value

    XCTAssertEqual(newest, "15.23.5")
  }
}
