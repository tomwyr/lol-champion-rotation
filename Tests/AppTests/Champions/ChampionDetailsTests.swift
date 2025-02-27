import XCTVapor

@testable import App

class ChampionDetailsTests: AppTests {
  func testUnknownChampion() async throws {
    _ = try await testConfigureWith(
      idHasherSecretKey: idHasherSecretKey,
      idHasherNonce: idHasherNonce,
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne")
      ],
      dbPatchVersions: [.init(value: "15.0.1")],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/champions/\(uuidString("2"))"
    ) { res async in
      XCTAssertEqual(res.status, .notFound)
    }
  }

  func testKnownChampion() async throws {
    _ = try await testConfigureWith(
      idHasherSecretKey: idHasherSecretKey,
      idHasherNonce: idHasherNonce,
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne", title: "the Eternal Nightmare")
      ],
      dbPatchVersions: [.init(value: "15.0.1")],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/champions/\(uuidString("1"))"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "id": uuidString("1"),
          "imageUrl": imageUrl("Nocturne"),
          "name": "Nocturne",
          "title": "the Eternal Nightmare",
          "availability": [
            [
              "rotationType": "regular",
              "current": false,
            ],
            [
              "rotationType": "beginner",
              "current": false,
            ],
          ],
        ]
      )
    }
  }

  func testChampionInCurrentRotation() async throws {
    _ = try await testConfigureWith(
      idHasherSecretKey: idHasherSecretKey,
      idHasherNonce: idHasherNonce,
      dbRegularRotations: [
        .init(id: uuid("1"), observedAt: .iso("2024-11-14T12:00:00Z")!, champions: ["Nocturne"])
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne", title: "the Eternal Nightmare")
      ],
      dbPatchVersions: [.init(value: "15.0.1")],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/champions/\(uuidString("1"))"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "id": uuidString("1"),
          "imageUrl": imageUrl("Nocturne"),
          "name": "Nocturne",
          "title": "the Eternal Nightmare",
          "availability": [
            [
              "current": true,
              "rotationType": "regular",
              "lastAvailable": "2024-11-14T12:00:00Z",
            ],
            [
              "rotationType": "beginner",
              "current": false,
            ],
          ],
        ]
      )
    }
  }

  func testChampionInPreviousRotation() async throws {
    _ = try await testConfigureWith(
      idHasherSecretKey: idHasherSecretKey,
      idHasherNonce: idHasherNonce,
      dbBeginnerRotations: [
        .init(
          id: uuid("1"), observedAt: .iso("2024-11-14T12:00:00Z")!, maxLevel: 10,
          champions: ["Nocturne"])
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne", title: "the Eternal Nightmare")
      ],
      dbPatchVersions: [.init(value: "15.0.1")],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/champions/\(uuidString("1"))"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "id": uuidString("1"),
          "imageUrl": imageUrl("Nocturne"),
          "name": "Nocturne",
          "title": "the Eternal Nightmare",
          "availability": [
            [
              "rotationType": "regular",
              "current": false,
            ],
            [
              "rotationType": "beginner",
              "current": true,
              "lastAvailable": "2024-11-14T12:00:00Z",
            ],
          ],
        ]
      )
    }
  }
}
