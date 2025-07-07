import XCTest

@testable import App

final class SlugGeneratorTests: XCTestCase {
  func testFirstWeekOfSeason() throws {
    let slug = try SlugGenerator().resolve(
      rotationStart: .isoDate("2025-01-05")!,
      versions: [
        .init(observedAt: .isoDate("2025-01-03")!, value: "15.1.0")
      ],
    )
    XCTAssertEqual(slug, "s15w1")
  }

  func testSeasonWithMultipleVersions() throws {
    let slug = try SlugGenerator().resolve(
      rotationStart: .isoDate("2025-01-25")!,
      versions: [
        .init(observedAt: .isoDate("2025-01-03")!, value: "15.1.0"),
        .init(observedAt: .isoDate("2025-01-10")!, value: "15.2.0"),
        .init(observedAt: .isoDate("2025-01-17")!, value: "15.3.0"),
        .init(observedAt: .isoDate("2025-01-24")!, value: "15.4.0"),
      ],
    )
    XCTAssertEqual(slug, "s15w4")
  }

  func testMultipleSeasons() throws {
    let slug = try SlugGenerator().resolve(
      rotationStart: .isoDate("2025-01-25")!,
      versions: [
        .init(observedAt: .isoDate("2024-12-06")!, value: "14.1.0"),
        .init(observedAt: .isoDate("2024-12-13")!, value: "14.2.0"),
        .init(observedAt: .isoDate("2024-12-20")!, value: "14.3.0"),
        .init(observedAt: .isoDate("2024-12-27")!, value: "14.4.0"),
        .init(observedAt: .isoDate("2025-01-03")!, value: "15.1.0"),
        .init(observedAt: .isoDate("2025-01-10")!, value: "15.2.0"),
        .init(observedAt: .isoDate("2025-01-17")!, value: "15.3.0"),
        .init(observedAt: .isoDate("2025-01-24")!, value: "15.4.0"),
      ],
    )
    XCTAssertEqual(slug, "s15w4")
  }

  func testVersionInPreviousSeason() throws {
    let slug = try SlugGenerator().resolve(
      rotationStart: .isoDate("2024-12-23")!,
      versions: [
        .init(observedAt: .isoDate("2024-12-06")!, value: "14.1.0"),
        .init(observedAt: .isoDate("2024-12-13")!, value: "14.2.0"),
        .init(observedAt: .isoDate("2024-12-20")!, value: "14.3.0"),
        .init(observedAt: .isoDate("2024-12-27")!, value: "14.4.0"),
        .init(observedAt: .isoDate("2025-01-03")!, value: "15.1.0"),
        .init(observedAt: .isoDate("2025-01-10")!, value: "15.2.0"),
        .init(observedAt: .isoDate("2025-01-17")!, value: "15.3.0"),
        .init(observedAt: .isoDate("2025-01-24")!, value: "15.4.0"),
      ],
    )
    XCTAssertEqual(slug, "s14w3")
  }

  func testMultipleRotations() throws {
    let slugs = try SlugGenerator().resolveAll(
      rotationStarts: [
        .isoDate("2024-12-09")!,
        .isoDate("2024-12-23")!,
        .isoDate("2024-12-31")!,
        .isoDate("2025-01-04")!,
        .isoDate("2025-01-09")!,
        .isoDate("2025-01-27")!,
      ],
      versions: [
        .init(observedAt: .isoDate("2024-12-06")!, value: "14.1.0"),
        .init(observedAt: .isoDate("2024-12-13")!, value: "14.2.0"),
        .init(observedAt: .isoDate("2024-12-20")!, value: "14.3.0"),
        .init(observedAt: .isoDate("2024-12-27")!, value: "14.4.0"),
        .init(observedAt: .isoDate("2025-01-03")!, value: "15.1.0"),
        .init(observedAt: .isoDate("2025-01-10")!, value: "15.2.0"),
        .init(observedAt: .isoDate("2025-01-17")!, value: "15.3.0"),
        .init(observedAt: .isoDate("2025-01-24")!, value: "15.4.0"),
      ],
    )
    XCTAssertEqual(
      slugs,
      ["s14w1", "s14w3", "s14w4", "s15w1", "s15w1", "s15w4"],
    )
  }

  func testNonUniqueSlug() throws {
    let slug = try SlugGenerator().resolveUnique(
      rotationStart: .isoDate("2025-01-25")!,
      versions: [
        .init(observedAt: .isoDate("2025-01-03")!, value: "15.1.0"),
        .init(observedAt: .isoDate("2025-01-10")!, value: "15.2.0"),
        .init(observedAt: .isoDate("2025-01-17")!, value: "15.3.0"),
        .init(observedAt: .isoDate("2025-01-24")!, value: "15.4.0"),
      ],
      existingSlugs: ["s15w4", "s15w4-1"],
    )
    XCTAssertEqual(slug, "s15w4-2")
  }

  func testMultipleNonUniqueSlug() throws {
    let slugs = try SlugGenerator().resolveAllUnique(
      rotationStarts: [
        .isoDate("2024-12-09")!,
        .isoDate("2024-12-31")!,
        .isoDate("2025-01-07")!,
        .isoDate("2025-01-09")!,
      ],
      versions: [
        .init(observedAt: .isoDate("2024-12-06")!, value: "14.1.0"),
        .init(observedAt: .isoDate("2024-12-13")!, value: "14.2.0"),
        .init(observedAt: .isoDate("2024-12-20")!, value: "14.3.0"),
        .init(observedAt: .isoDate("2024-12-27")!, value: "14.4.0"),
        .init(observedAt: .isoDate("2025-01-03")!, value: "15.1.0"),
        .init(observedAt: .isoDate("2025-01-10")!, value: "15.2.0"),
        .init(observedAt: .isoDate("2025-01-17")!, value: "15.3.0"),
        .init(observedAt: .isoDate("2025-01-24")!, value: "15.4.0"),
      ],
      existingSlugs: [
        "s14w1", "s14w4", "s14w4-1", "s14w4-2", "s15w1", "s15w1-1", "s15w1-3",
      ],
    )
    XCTAssertEqual(
      slugs,
      ["s14w1-2", "s14w4-3", "s15w1-2", "s15w1-4"],
    )
  }
}
