import XCTest

@testable import App

final class UpdateObservRotationTests: AppTests {
  func testUnauthorizedUser() async throws {
    _ = try await testConfigureWith()

    try await app.test(
      .POST, "/rotations/\(uuidString("1"))/observe",
      body: ["observing": true]
    ) { res async in
      XCTAssertEqual(res.status, .unauthorized)
    }
  }

  func testAddingNonObservedRotation() async throws {
    _ = try await testConfigureWith(
      dbUserWatchlists: [
        .init(userId: mobileUserId, rotations: [uuidString("2")])
      ]
    )

    try await app.test(
      .POST, "/rotations/\(uuidString("1"))/observe",
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
      dbUserWatchlists: [
        .init(userId: mobileUserId, rotations: [uuidString("1")])
      ]
    )

    try await app.test(
      .POST, "/rotations/\(uuidString("1"))/observe",
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
      dbUserWatchlists: [
        .init(userId: mobileUserId, rotations: [uuidString("1")])
      ]
    )

    try await app.test(
      .POST, "/rotations/\(uuidString("1"))/observe",
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
      dbUserWatchlists: [
        .init(userId: mobileUserId, rotations: [uuidString("2")])
      ]
    )

    try await app.test(
      .POST, "/rotations/\(uuidString("1"))/observe",
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
      dbUserWatchlists: []
    )

    try await app.test(
      .POST, "/rotations/\(uuidString("1"))/observe",
      headers: reqHeaders(accessToken: mobileToken),
      body: ["observing": true]
    ) { res async throws in
      let watchlists = try await dbUserWatchlists(userId: mobileUserId)
      XCTAssertEqual(res.status, .ok)
      XCTAssertEqual(watchlists?.rotations, [uuidString("1")])
    }
  }

}
