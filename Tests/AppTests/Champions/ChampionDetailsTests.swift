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
      .GET, "/champions/Garen"
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
      .GET, "/champions/Nocturne"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "id": "nocturne",
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

  func testKnownChampionCaseInsensitive() async throws {
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
      .GET, "/champions/nocturne"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "id": "nocturne",
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

  func testChampionWithMissingReleaseDate() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbChampions: [
        .init(
          id: uuid("1"), riotId: "Nocturne",
          name: "Nocturne", title: "the Eternal Nightmare")
      ],
      dbPatchVersions: [.init(value: "15.0.1")],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/champions/Nocturne"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "id": "nocturne",
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
            "occurrences": 0
          ],
          "history": [],
        ]
      )
    }
  }

  func testChampionInCurrentRotation() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Nocturne"],
          slug: "s1w1",
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
      .GET, "/champions/Nocturne"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "id": "nocturne",
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
              "id": "s1w1",
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
      .GET, "/champions/Nocturne"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "id": "nocturne",
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
          champions: ["Nocturne", "Senna"],
          slug: "s1w4",
        ),
        .init(
          id: uuid("3"), observedAt: .iso("2024-11-13T12:00:00Z")!,
          champions: ["Nocturne", "Senna", "Fiora"],
          slug: "s1w3",
        ),
        .init(
          id: uuid("2"), observedAt: .iso("2024-11-12T12:00:00Z")!,
          champions: ["Senna"],
          slug: "s1w2",
        ),
        .init(
          id: uuid("1"), observedAt: .iso("2024-11-11T12:00:00Z")!,
          champions: ["Nocturne", "Senna", "Fiora"],
          slug: "s1w1",
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
      .GET, "/champions/Nocturne"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "id": "nocturne",
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
              "id": "s1w4",
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
              "id": "s1w3",
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
              "id": "s1w1",
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
          champions: ["Senna", "Fiora"],
          slug: "s1w4",
        ),
        .init(
          id: uuid("3"), observedAt: .iso("2024-11-13T12:00:00Z")!,
          champions: ["Senna"],
          slug: "s1w3",
        ),
        .init(
          id: uuid("2"), observedAt: .iso("2024-11-12T12:00:00Z")!,
          champions: ["Nocturne", "Senna"],
          slug: "s1w2",
        ),
        .init(
          id: uuid("1"), observedAt: .iso("2024-11-11T12:00:00Z")!,
          champions: ["Senna", "Fiora"],
          slug: "s1w1",
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
      .GET, "/champions/Nocturne"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "id": "nocturne",
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
              "id": "s1w2",
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
          champions: ["Fiora", "Nocturne"],
          slug: "s1w4",
        ),
        .init(
          id: uuid("3"), observedAt: .iso("2024-11-13T12:00:00Z")!,
          champions: ["Senna"],
          slug: "s1w3",
        ),
        .init(
          id: uuid("2"), observedAt: .iso("2024-11-12T12:00:00Z")!,
          champions: ["Senna"],
          slug: "s1w2",
        ),
        .init(
          id: uuid("1"), observedAt: .iso("2024-11-11T12:00:00Z")!,
          champions: ["Senna", "Fiora"],
          slug: "s1w1",
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
      .GET, "/champions/Nocturne"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "id": "nocturne",
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
              "id": "s1w4",
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
          champions: ["Fiora", "Senna"],
          slug: "s1w4",
        ),
        .init(
          id: uuid("3"), observedAt: .iso("2024-11-13T12:00:00Z")!,
          champions: ["Senna"],
          slug: "s1w3",
        ),
        .init(
          id: uuid("2"), observedAt: .iso("2024-11-12T12:00:00Z")!,
          champions: ["Senna"],
          slug: "s1w2",
        ),
        .init(
          id: uuid("1"), observedAt: .iso("2024-11-11T12:00:00Z")!,
          champions: ["Senna", "Fiora"],
          slug: "s1w1",
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
      .GET, "/champions/Nocturne"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "id": "nocturne",
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
          champions: ["Fiora", "Senna", "Nocturne"],
          slug: "s1w5",
        ),
        .init(
          id: uuid("4"), observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Fiora", "Nocturne"],
          slug: "s1w4",
        ),
        .init(
          id: uuid("3"), observedAt: .iso("2024-11-13T12:00:00Z")!,
          champions: ["Senna"],
          slug: "s1w3",
        ),
        .init(
          id: uuid("2"), observedAt: .iso("2024-11-12T12:00:00Z")!,
          champions: ["Senna", "Fiora"],
          slug: "s1w2",
        ),
        .init(
          id: uuid("1"), observedAt: .iso("2024-11-11T12:00:00Z")!,
          champions: ["Fiora"],
          slug: "s1w1",
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
      .GET, "/champions/Nocturne"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "id": "nocturne",
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
              "id": "s1w5",
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
              "id": "s1w4",
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

  func testUserObservingChampion() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbChampions: [
        .init(
          id: uuid("1"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Nocturne",
          name: "Nocturne", title: "the Eternal Nightmare")
      ],
      dbPatchVersions: [.init(value: "15.0.1")],
      dbUserWatchlists: [
        .init(userId: mobileUserId, champions: [uuidString("1")])
      ],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/champions/Nocturne",
      headers: reqHeaders(accessToken: mobileToken)
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "id": "nocturne",
          "imageUrl": imageUrl("Nocturne"),
          "name": "Nocturne",
          "title": "the Eternal Nightmare",
          "observing": true,
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

  func testUserNotObservingChampion() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbChampions: [
        .init(
          id: uuid("1"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Nocturne",
          name: "Nocturne", title: "the Eternal Nightmare")
      ],
      dbPatchVersions: [.init(value: "15.0.1")],
      dbUserWatchlists: [
        .init(userId: mobileUserId, champions: [uuidString("2")])
      ],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/champions/Nocturne",
      headers: reqHeaders(accessToken: mobileToken)
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "id": "nocturne",
          "imageUrl": imageUrl("Nocturne"),
          "name": "Nocturne",
          "title": "the Eternal Nightmare",
          "observing": false,
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
}
