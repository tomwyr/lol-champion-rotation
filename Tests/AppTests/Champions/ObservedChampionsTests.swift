import XCTest

@testable import App

final class ObservedChampionsTests: AppTests {
  func testUnauthorizedUser() async throws {
    _ = try await testConfigureWith(
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Nocturne"]
        )
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne")
      ],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/champions/observed"
    ) { res async in
      XCTAssertEqual(res.status, .unauthorized)
    }
  }

  func testAuthorizedUser() async throws {
    _ = try await testConfigureWith(
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-07T12:00:00Z")!,
          champions: ["Nocturne"]
        )
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Senna", name: "Senna"),
        .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
        .init(id: uuid("3"), riotId: "Nocturne", name: "Nocturne"),

      ],
      dbUserWatchlists: [
        .init(
          userId: mobileUserId,
          champions: [uuidString("1"), uuidString("3")]
        )
      ],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/champions/observed",
      headers: reqHeaders(accessToken: mobileToken)
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "champions": [
            [
              "id": uuidString("3"),
              "name": "Nocturne",
              "current": true,
              "imageUrl": imageUrl("Nocturne"),
            ],
            [
              "id": uuidString("1"),
              "name": "Senna",
              "current": false,
              "imageUrl": imageUrl("Senna"),
            ],
          ]
        ]
      )
    }
  }

  func testUserWithoutWatchlist() async throws {
    _ = try await testConfigureWith(
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-07T12:00:00Z")!,
          champions: ["Nocturne"]
        )
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne")

      ],
      dbUserWatchlists: [],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/champions/observed",
      headers: reqHeaders(accessToken: mobileToken)
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "champions": []
        ]
      )
    }
  }
}
