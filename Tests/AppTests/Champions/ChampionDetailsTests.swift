import XCTVapor

@testable import App

class ChampionDetailsTests: AppTests {
  func testUnknownChampion() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbChampions: [
        .init(
          id: uuid("1"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Nocturne",
          name: "Nocturne", title: "the Eternal Nightmare")
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
      idHasherSeed: idHasherSeed,
      dbChampions: [
        .init(
          id: uuid("1"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Nocturne",
          name: "Nocturne", title: "the Eternal Nightmare")
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
          "history": [
            [
              "type": "release",
              "releasedAt": "2024-01-01T00:00:00Z",
            ]
          ],
        ]
      )
    }
  }

  func testChampionInCurrentRotation() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(id: uuid("1"), observedAt: .iso("2024-11-14T12:00:00Z")!, champions: ["Nocturne"])
      ],
      dbChampions: [
        .init(
          id: uuid("1"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Nocturne",
          name: "Nocturne", title: "the Eternal Nightmare")
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
            "occurrences": 1,
            "popularity": 1,
            "currentStreak": 1,
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
            ],
            [
              "type": "release",
              "releasedAt": "2024-01-01T00:00:00Z",
            ],
          ],
        ]
      )
    }
  }

  func testChampionInPreviousRotation() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbBeginnerRotations: [
        .init(
          id: uuid("1"), observedAt: .iso("2024-11-14T12:00:00Z")!, maxLevel: 10,
          champions: ["Nocturne"]
        )
      ],
      dbChampions: [
        .init(
          id: uuid("1"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Nocturne",
          name: "Nocturne", title: "the Eternal Nightmare")
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
          "history": [
            [
              "type": "release",
              "releasedAt": "2024-01-01T00:00:00Z",
            ]
          ],
        ]
      )
    }
  }

  func testOverviewWithPositiveStreak() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
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
        .init(
          id: uuid("1"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Nocturne",
          name: "Nocturne", title: "the Eternal Nightmare"),
        .init(
          id: uuid("2"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Senna", name: "Senna",
          title: "the Redeemer"),
        .init(
          id: uuid("3"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Fiora", name: "Fiora",
          title: "the Grand Duelist"),
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
                imageUrl("Senna"),
                imageUrl("Nocturne"),
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
                imageUrl("Fiora"),
                imageUrl("Senna"),
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
                imageUrl("Fiora"),
                imageUrl("Senna"),
              ],
            ],
            [
              "type": "release",
              "releasedAt": "2024-01-01T00:00:00Z",
            ],
          ],
        ]
      )
    }
  }

  func testOverviewWithNegativeStreak() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
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
        .init(
          id: uuid("1"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Nocturne",
          name: "Nocturne", title: "the Eternal Nightmare"),
        .init(
          id: uuid("2"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Senna", name: "Senna",
          title: "the Redeemer"),
        .init(
          id: uuid("3"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Fiora", name: "Fiora",
          title: "the Grand Duelist"),
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
                imageUrl("Senna"),
                imageUrl("Nocturne"),
              ],
            ],
            [
              "type": "bench",
              "rotationsMissed": 1,
            ],
            [
              "type": "release",
              "releasedAt": "2024-01-01T00:00:00Z",
            ],
          ],
        ]
      )
    }
  }

  func testChampionReleasedBetweenRotation() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          id: uuid("4"), observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Fiora", "Nocturne"]
        ),
        .init(
          id: uuid("3"), observedAt: .iso("2024-11-13T12:00:00Z")!,
          champions: ["Senna"]
        ),
        .init(
          id: uuid("2"), observedAt: .iso("2024-11-12T12:00:00Z")!,
          champions: ["Senna"]
        ),
        .init(
          id: uuid("1"), observedAt: .iso("2024-11-11T12:00:00Z")!,
          champions: ["Senna", "Fiora"]
        ),
      ],
      dbChampions: [
        .init(
          id: uuid("1"), releasedAt: .iso("2024-11-13T00:00:00Z")!, riotId: "Nocturne",
          name: "Nocturne", title: "the Eternal Nightmare"),
        .init(
          id: uuid("2"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Senna", name: "Senna",
          title: "the Redeemer"),
        .init(
          id: uuid("3"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Fiora", name: "Fiora",
          title: "the Grand Duelist"),
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
            "occurrences": 1,
            "popularity": 3,
            "currentStreak": 1,
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
                imageUrl("Fiora"),
                imageUrl("Nocturne"),
              ],
            ],
            [
              "type": "bench",
              "rotationsMissed": 1,
            ],
            [
              "type": "release",
              "releasedAt": "2024-11-13T00:00:00Z",
            ],
          ],
        ]
      )
    }
  }

  func testChampionReleasedBetweenRotationWithNegativeStreak() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          id: uuid("4"), observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Fiora", "Senna"]
        ),
        .init(
          id: uuid("3"), observedAt: .iso("2024-11-13T12:00:00Z")!,
          champions: ["Senna"]
        ),
        .init(
          id: uuid("2"), observedAt: .iso("2024-11-12T12:00:00Z")!,
          champions: ["Senna"]
        ),
        .init(
          id: uuid("1"), observedAt: .iso("2024-11-11T12:00:00Z")!,
          champions: ["Senna", "Fiora"]
        ),
      ],
      dbChampions: [
        .init(
          id: uuid("1"), releasedAt: .iso("2024-11-13T00:00:00Z")!, riotId: "Nocturne",
          name: "Nocturne", title: "the Eternal Nightmare"),
        .init(
          id: uuid("2"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Senna", name: "Senna",
          title: "the Redeemer"),
        .init(
          id: uuid("3"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Fiora", name: "Fiora",
          title: "the Grand Duelist"),
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
            "popularity": 3,
            "currentStreak": -2,
          ],
          "history": [
            [
              "type": "bench",
              "rotationsMissed": 2,
            ],
            [
              "type": "release",
              "releasedAt": "2024-11-13T00:00:00Z",
            ],
          ],
        ]
      )
    }
  }

  func testChampionWithHighRelativeScore() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          id: uuid("5"), observedAt: .iso("2024-11-15T12:00:00Z")!,
          champions: ["Fiora", "Senna", "Nocturne"]
        ),
        .init(
          id: uuid("4"), observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Fiora", "Nocturne"]
        ),
        .init(
          id: uuid("3"), observedAt: .iso("2024-11-13T12:00:00Z")!,
          champions: ["Senna"]
        ),
        .init(
          id: uuid("2"), observedAt: .iso("2024-11-12T12:00:00Z")!,
          champions: ["Senna", "Fiora"]
        ),
        .init(
          id: uuid("1"), observedAt: .iso("2024-11-11T12:00:00Z")!,
          champions: ["Fiora"]
        ),
      ],
      dbChampions: [
        .init(
          id: uuid("1"), releasedAt: .iso("2024-11-14T00:00:00Z")!, riotId: "Nocturne",
          name: "Nocturne", title: "the Eternal Nightmare"),
        .init(
          id: uuid("2"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Senna", name: "Senna",
          title: "the Redeemer"),
        .init(
          id: uuid("3"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Fiora", name: "Fiora",
          title: "the Grand Duelist"),
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
              "lastAvailable": "2024-11-15T12:00:00Z",
            ],
            [
              "rotationType": "beginner",
              "current": false,
            ],
          ],
          "overview": [
            "occurrences": 2,
            "popularity": 2,
            "currentStreak": 2,
          ],
          "history": [
            [
              "type": "rotation",
              "id": uuidString("5"),
              "duration": [
                "start": "2024-11-15T12:00:00Z",
                "end": "2024-11-22T12:00:00Z",
              ],
              "current": true,
              "championImageUrls": [
                imageUrl("Senna"),
                imageUrl("Fiora"),
                imageUrl("Nocturne"),
              ],
            ],
            [
              "type": "rotation",
              "id": uuidString("4"),
              "duration": [
                "start": "2024-11-14T12:00:00Z",
                "end": "2024-11-15T12:00:00Z",
              ],
              "current": false,
              "championImageUrls": [
                imageUrl("Fiora"),
                imageUrl("Nocturne"),
              ],
            ],
            [
              "type": "release",
              "releasedAt": "2024-11-14T00:00:00Z",
            ],
          ],
        ]
      )
    }
  }
}
