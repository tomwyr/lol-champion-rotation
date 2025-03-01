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
          "overview": [
            "occurrences": 0,
            "popularity": 1,
            "currentStreak": 0,
          ],
          "history": [],
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
          "overview": [
            "occurrences": 1,
            "popularity": 1,
            "currentStreak": 0,
          ],
          "history": [
            [
              "type": "rotation",
              "id": uuidString("1"),
              "duration": [
                "start": "2024-11-14T12:00:00Z",
                "end": "2024-11-21T12:00:00Z",
              ],
              "current": true,
              "championImageUrls": [imageUrl("Nocturne")],
            ]
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
          champions: ["Nocturne"]
        )
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
          "overview": [
            "occurrences": 0,
            "popularity": 1,
            "currentStreak": 0,
          ],
          "history": [],
        ]
      )
    }
  }

  func testChampionOverivewWithPositiveStreak() async throws {
    _ = try await testConfigureWith(
      idHasherSecretKey: idHasherSecretKey,
      idHasherNonce: idHasherNonce,
      dbRegularRotations: [
        .init(
          id: uuid("4"), observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Nocturne", "Senna"]
        ),
        .init(
          id: uuid("3"), observedAt: .iso("2024-11-13T12:00:00Z")!,
          champions: ["Nocturne", "Senna", "Fiora"]
        ),
        .init(
          id: uuid("2"), observedAt: .iso("2024-11-12T12:00:00Z")!,
          champions: ["Senna"]
        ),
        .init(
          id: uuid("1"), observedAt: .iso("2024-11-11T12:00:00Z")!,
          champions: ["Nocturne", "Senna", "Fiora"]
        ),
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne", title: "the Eternal Nightmare"),
        .init(id: uuid("2"), riotId: "Senna", name: "Senna", title: "the Redeemer"),
        .init(id: uuid("3"), riotId: "Fiora", name: "Fiora", title: "the Grand Duelist"),
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
              "current": true,
              "lastAvailable": "2024-11-14T12:00:00Z",
            ],
            [
              "rotationType": "beginner",
              "current": false,
            ],
          ],
          "overview": [
            "occurrences": 3,
            "popularity": 2,
            "currentStreak": 2,
          ],
          "history": [
            [
              "type": "rotation",
              "id": uuidString("4"),
              "duration": [
                "start": "2024-11-14T12:00:00Z",
                "end": "2024-11-21T12:00:00Z",
              ],
              "current": true,
              "championImageUrls": [
                imageUrl("Nocturne"),
                imageUrl("Senna"),
              ],
            ],
            [
              "type": "rotation",
              "id": uuidString("3"),
              "duration": [
                "start": "2024-11-13T12:00:00Z",
                "end": "2024-11-14T12:00:00Z",
              ],
              "current": false,
              "championImageUrls": [
                imageUrl("Nocturne"),
                imageUrl("Senna"),
                imageUrl("Fiora"),
              ],
            ],
            [
              "type": "bench",
              "rotationsMissed": 1,
            ],
            [
              "type": "rotation",
              "id": uuidString("1"),
              "duration": [
                "start": "2024-11-11T12:00:00Z",
                "end": "2024-11-12T12:00:00Z",
              ],
              "current": false,
              "championImageUrls": [
                imageUrl("Nocturne"),
                imageUrl("Senna"),
                imageUrl("Fiora"),
              ],
            ],
          ],
        ]
      )
    }
  }

  func testChampionOverivewWithNegativeStreak() async throws {
    _ = try await testConfigureWith(
      idHasherSecretKey: idHasherSecretKey,
      idHasherNonce: idHasherNonce,
      dbRegularRotations: [
        .init(
          id: uuid("4"), observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Senna", "Fiora"]
        ),
        .init(
          id: uuid("3"), observedAt: .iso("2024-11-13T12:00:00Z")!,
          champions: ["Senna"]
        ),
        .init(
          id: uuid("2"), observedAt: .iso("2024-11-12T12:00:00Z")!,
          champions: ["Nocturne", "Senna"]
        ),
        .init(
          id: uuid("1"), observedAt: .iso("2024-11-11T12:00:00Z")!,
          champions: ["Senna", "Fiora"]
        ),
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne", title: "the Eternal Nightmare"),
        .init(id: uuid("2"), riotId: "Senna", name: "Senna", title: "the Redeemer"),
        .init(id: uuid("3"), riotId: "Fiora", name: "Fiora", title: "the Grand Duelist"),
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
              "lastAvailable": "2024-11-12T12:00:00Z",
            ],
            [
              "rotationType": "beginner",
              "current": false,
            ],
          ],
          "overview": [
            "occurrences": 1,
            "popularity": 3,
            "currentStreak": -2,
          ],
          "history": [
            [
              "type": "bench",
              "rotationsMissed": 2,
            ],
            [
              "type": "rotation",
              "id": uuidString("2"),
              "duration": [
                "start": "2024-11-12T12:00:00Z",
                "end": "2024-11-13T12:00:00Z",
              ],
              "current": false,
              "championImageUrls": [
                imageUrl("Nocturne"),
                imageUrl("Senna"),
              ],
            ],
            [
              "type": "bench",
              "rotationsMissed": 1,
            ],
          ],
        ]
      )
    }
  }
}
