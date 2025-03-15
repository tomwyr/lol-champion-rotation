import XCTest

@testable import App

final class ObservedRotationsTests: AppTests {
  func testUnauthorizedUser() async throws {
    _ = try await testConfigureWith(
      dbRegularRotations: [
        .init(
          id: uuid("2"),
          observedAt: .iso("2024-11-21T12:00:00Z")!,
          champions: ["Nocturne"]
        ),
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Nocturne"]
        ),
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne")
      ],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/rotations/observed"
    ) { res async in
      XCTAssertEqual(res.status, .unauthorized)
    }
  }

  func testAuthorizedUser() async throws {
    _ = try await testConfigureWith(
      dbRegularRotations: [
        .init(
          id: uuid("3"),
          observedAt: .iso("2024-11-21T12:00:00Z")!,
          champions: ["Garen"]
        ),
        .init(
          id: uuid("2"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Nocturne"]
        ),
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-07T12:00:00Z")!,
          champions: ["Nocturne"]
        ),
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
        .init(id: uuid("2"), riotId: "Garen", name: "Garen"),

      ],
      dbUserWatchlists: [
        .init(
          userId: mobileUserId,
          rotations: [uuidString("1"), uuidString("3")]
        )
      ],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/rotations/observed",
      headers: reqHeaders(accessToken: mobileToken)
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "rotations": [
            [
              "id": uuidString("3"),
              "current": true,
              "duration": [
                "start": "2024-11-21T12:00:00Z",
                "end": "2024-11-28T12:00:00Z",
              ],
              "championImageUrls": [
                imageUrl("Garen")
              ],
            ],
            [
              "id": uuidString("1"),
              "current": false,
              "duration": [
                "start": "2024-11-07T12:00:00Z",
                "end": "2024-11-14T12:00:00Z",
              ],
              "championImageUrls": [
                imageUrl("Nocturne")
              ],
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
      .GET, "/rotations/observed",
      headers: reqHeaders(accessToken: mobileToken)
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "rotations": []
        ]
      )
    }
  }
}
