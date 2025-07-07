import XCTest

@testable import App

final class UpdateObserveRotationTests: AppTests {
  func testUnauthorizedUser() async throws {
    _ = try await testConfigureWith(
      dbRegularRotations: [
        .init(id: uuid("1"), slug: "s1w1")
      ],
    )

    try await app.test(
      .POST, "/rotations/s1w1/observe",
      body: ["observing": true]
    ) { res async in
      XCTAssertEqual(res.status, .unauthorized)
    }
  }

  func testAddingNonObservedRotation() async throws {
    _ = try await testConfigureWith(
      dbRegularRotations: [
        .init(id: uuid("1"), slug: "s1w1")
      ],
      dbUserWatchlists: [
        .init(userId: mobileUserId, rotations: [uuidString("2")])
      ],
    )

    try await app.test(
      .POST, "/rotations/s1w1/observe",
      headers: reqHeaders(accessToken: mobileToken),
      body: ["observing": true]
    ) { res async throws in
      let watchlists = try await dbUserWatchlists(userId: mobileUserId)
      XCTAssertEqual(res.status, .ok)
      XCTAssertEqual(watchlists?.rotations, [uuidString("2"), uuidString("1")])
    }
  }

  func testAddingObservedRotation() async throws {
    _ = try await testConfigureWith(
      dbRegularRotations: [
        .init(id: uuid("1"), slug: "s1w1")
      ],
      dbUserWatchlists: [
        .init(userId: mobileUserId, rotations: [uuidString("1")])
      ]
    )

    try await app.test(
      .POST, "/rotations/s1w1/observe",
      headers: reqHeaders(accessToken: mobileToken),
      body: ["observing": true]
    ) { res async throws in
      let watchlists = try await dbUserWatchlists(userId: mobileUserId)
      XCTAssertEqual(res.status, .ok)
      XCTAssertEqual(watchlists?.rotations, [uuidString("1")])
    }
  }

  func testRemovingObservedRotation() async throws {
    _ = try await testConfigureWith(
      dbRegularRotations: [
        .init(id: uuid("1"), slug: "s1w1")
      ],
      dbUserWatchlists: [
        .init(userId: mobileUserId, rotations: [uuidString("1")])
      ]
    )

    try await app.test(
      .POST, "/rotations/s1w1/observe",
      headers: reqHeaders(accessToken: mobileToken),
      body: ["observing": false]
    ) { res async throws in
      let watchlists = try await dbUserWatchlists(userId: mobileUserId)
      XCTAssertEqual(res.status, .ok)
      XCTAssertEqual(watchlists?.rotations, [])
    }
  }

  func testRemovingNonObservedRotation() async throws {
    _ = try await testConfigureWith(
      dbRegularRotations: [
        .init(id: uuid("1"), slug: "s1w1")
      ],
      dbUserWatchlists: [
        .init(userId: mobileUserId, rotations: [uuidString("2")])
      ]
    )

    try await app.test(
      .POST, "/rotations/s1w1/observe",
      headers: reqHeaders(accessToken: mobileToken),
      body: ["observing": false]
    ) { res async throws in
      let watchlists = try await dbUserWatchlists(userId: mobileUserId)
      XCTAssertEqual(res.status, .ok)
      XCTAssertEqual(watchlists?.rotations, [uuidString("2")])
    }
  }

  func testAddingWithoutWatchlist() async throws {
    _ = try await testConfigureWith(
      dbRegularRotations: [
        .init(id: uuid("1"), slug: "s1w1")
      ],
      dbUserWatchlists: []
    )

    try await app.test(
      .POST, "/rotations/s1w1/observe",
      headers: reqHeaders(accessToken: mobileToken),
      body: ["observing": true]
    ) { res async throws in
      let watchlists = try await dbUserWatchlists(userId: mobileUserId)
      XCTAssertEqual(res.status, .ok)
      XCTAssertEqual(watchlists?.rotations, [uuidString("1")])
    }
  }

}
