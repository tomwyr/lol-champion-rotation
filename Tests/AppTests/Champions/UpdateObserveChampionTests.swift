import XCTest

@testable import App

final class UpdateObservChampionTests: AppTests {
  func testUnauthorizedUser() async throws {
    _ = try await testConfigureWith()

    try await app.test(
      .POST, "/champions/Nocturne/observe",
      body: ["observing": true]
    ) { res async in
      XCTAssertEqual(res.status, .unauthorized)
    }
  }

  func testAddingNonObservedChampion() async throws {
    _ = try await testConfigureWith(
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne"),
        .init(id: uuid("2"), riotId: "Garen"),
      ],
      dbUserWatchlists: [
        .init(userId: mobileUserId, champions: [uuidString("2")])
      ],
    )

    try await app.test(
      .POST, "/champions/Nocturne/observe",
      headers: reqHeaders(accessToken: mobileToken),
      body: ["observing": true]
    ) { res async throws in
      let watchlists = try await dbUserWatchlists(userId: mobileUserId)
      XCTAssertEqual(res.status, .ok)
      XCTAssertEqual(watchlists?.champions, [uuidString("2"), uuidString("1")])
    }
  }

  func testAddingObservedChampion() async throws {
    _ = try await testConfigureWith(
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne")
      ],
      dbUserWatchlists: [
        .init(userId: mobileUserId, champions: [uuidString("1")])
      ]
    )

    try await app.test(
      .POST, "/champions/Nocturne/observe",
      headers: reqHeaders(accessToken: mobileToken),
      body: ["observing": true]
    ) { res async throws in
      let watchlists = try await dbUserWatchlists(userId: mobileUserId)
      XCTAssertEqual(res.status, .ok)
      XCTAssertEqual(watchlists?.champions, [uuidString("1")])
    }
  }

  func testRemovingObservedChampion() async throws {
    _ = try await testConfigureWith(
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne")
      ],
      dbUserWatchlists: [
        .init(userId: mobileUserId, champions: [uuidString("1")])
      ]
    )

    try await app.test(
      .POST, "/champions/Nocturne/observe",
      headers: reqHeaders(accessToken: mobileToken),
      body: ["observing": false]
    ) { res async throws in
      let watchlists = try await dbUserWatchlists(userId: mobileUserId)
      XCTAssertEqual(res.status, .ok)
      XCTAssertEqual(watchlists?.champions, [])
    }
  }

  func testRemovingNonObservedChampion() async throws {
    _ = try await testConfigureWith(
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne"),
        .init(id: uuid("2"), riotId: "Garen"),
      ],
      dbUserWatchlists: [
        .init(userId: mobileUserId, champions: [uuidString("2")])
      ]
    )

    try await app.test(
      .POST, "/champions/Nocturne/observe",
      headers: reqHeaders(accessToken: mobileToken),
      body: ["observing": false]
    ) { res async throws in
      let watchlists = try await dbUserWatchlists(userId: mobileUserId)
      XCTAssertEqual(res.status, .ok)
      XCTAssertEqual(watchlists?.champions, [uuidString("2")])
    }
  }

  func testAddingWithoutWatchlist() async throws {
    _ = try await testConfigureWith(
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne")
      ],
      dbUserWatchlists: [],
    )

    try await app.test(
      .POST, "/champions/Nocturne/observe",
      headers: reqHeaders(accessToken: mobileToken),
      body: ["observing": true]
    ) { res async throws in
      let watchlists = try await dbUserWatchlists(userId: mobileUserId)
      XCTAssertEqual(res.status, .ok)
      XCTAssertEqual(watchlists?.champions, [uuidString("1")])
    }
  }

  func testAddingChampionCaseInsensitive() async throws {
    _ = try await testConfigureWith(
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne")
      ],
      dbUserWatchlists: [
        .init(userId: mobileUserId, champions: [uuidString("1")])
      ]
    )

    try await app.test(
      .POST, "/champions/nocturne/observe",
      headers: reqHeaders(accessToken: mobileToken),
      body: ["observing": true]
    ) { res async throws in
      let watchlists = try await dbUserWatchlists(userId: mobileUserId)
      XCTAssertEqual(res.status, .ok)
      XCTAssertEqual(watchlists?.champions, [uuidString("1")])
    }
  }

  func testRemovingChampionCaseInsensitive() async throws {
    _ = try await testConfigureWith(
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne")
      ],
      dbUserWatchlists: [
        .init(userId: mobileUserId, champions: [uuidString("1")])
      ]
    )

    try await app.test(
      .POST, "/champions/nocturne/observe",
      headers: reqHeaders(accessToken: mobileToken),
      body: ["observing": false]
    ) { res async throws in
      let watchlists = try await dbUserWatchlists(userId: mobileUserId)
      XCTAssertEqual(res.status, .ok)
      XCTAssertEqual(watchlists?.champions, [])
    }
  }
}
