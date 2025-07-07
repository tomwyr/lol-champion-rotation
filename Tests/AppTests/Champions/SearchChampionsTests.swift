import XCTVapor

@testable import App

class SearchChampionsTests: AppTests {
  func testNoQueryParam() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Garen", "Sett"],
          slug: "s1w1",
        )
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
        .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
        .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
      ],
      dbPatchVersions: [.init(value: "15.0.1")],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/champions/search"
    ) { res async in
      XCTAssertEqual(res.status, .badRequest)
    }
  }

  func testNoMatchingChampions() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
        .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
        .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
      ],
      dbPatchVersions: [.init(value: "15.0.1")],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/champions/search?name=Lux"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "matches": []
        ]
      )
    }
  }

  func testChampionsWithExactMatch() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Garen", "Sett", "Nocturne"],
          slug: "s1w1",
        )
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
        .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
        .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
      ],
      dbPatchVersions: [.init(value: "15.0.1")],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/champions/search?name=Nocturne"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "matches": [
            [
              "champion": [
                "id": "nocturne",
                "imageUrl": imageUrl("Nocturne"),
                "name": "Nocturne",
              ],
              "availableIn": ["regular"],
            ]
          ]
        ]
      )
    }
  }

  func testChampionsWithNonExactMatch() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Garen", "Sett", "Nocturne"],
          slug: "s1w1",
        )
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
        .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
        .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
      ],
      dbPatchVersions: [.init(value: "15.0.1")],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/champions/search?name=oCtuRn"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "matches": [
            [
              "champion": [
                "id": "nocturne",
                "imageUrl": imageUrl("Nocturne"),
                "name": "Nocturne",
              ],
              "availableIn": ["regular"],
            ]
          ]
        ]
      )
    }
  }

  func testChampionsWithMultipleMatches() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Garen", "Sett", "Nocturne", "Rengar"],
          slug: "s1w1",
        )
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
        .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
        .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
        .init(id: uuid("4"), riotId: "Rengar", name: "Rengar"),
      ],
      dbPatchVersions: [.init(value: "15.0.1")],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/champions/search?name=En"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "matches": [
            [
              "champion": [
                "id": "rengar",
                "imageUrl": imageUrl("Rengar"),
                "name": "Rengar",
              ],
              "availableIn": ["regular"],
            ],
            [
              "champion": [
                "id": "garen",
                "imageUrl": imageUrl("Garen"),
                "name": "Garen",
              ],
              "availableIn": ["regular"],
            ],
          ]
        ]
      )
    }
  }

  func testChampionsWithMatchesInMultipleRotations() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-21T12:00:00Z")!,
          champions: ["Sett", "Nocturne", "Rengar"],
          slug: "s1w1",
        ),
        .init(
          id: uuid("2"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Garen", "Sett", "Rengar"],
          slug: "s1w2",
        ),
      ],
      dbBeginnerRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-21T12:00:00Z")!,
          maxLevel: 10,
          champions: ["Garen", "Nocturne", "Samira"]
        ),
        .init(
          id: uuid("2"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          maxLevel: 10,
          champions: ["Garen", "Sett", "Samira"]
        ),
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
        .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
        .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
        .init(id: uuid("4"), riotId: "Rengar", name: "Rengar"),
        .init(id: uuid("5"), riotId: "Samira", name: "Samira"),
      ],
      dbPatchVersions: [.init(value: "15.0.1")],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/champions/search?name=En"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "matches": [
            [
              "champion": [
                "id": "rengar",
                "imageUrl": imageUrl("Rengar"),
                "name": "Rengar",
              ],
              "availableIn": ["regular"],
            ],
            [
              "champion": [
                "id": "garen",
                "imageUrl": imageUrl("Garen"),
                "name": "Garen",
              ],
              "availableIn": ["beginner"],
            ],
          ]
        ]
      )
    }
  }

  func testChampionWithMatchInNameOnly() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Sett", "Nocturne", "Nunu"],
          slug: "s1w1",
        )
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
        .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
        .init(id: uuid("3"), riotId: "Nunu", name: "Nunu & Willump"),
      ],
      dbPatchVersions: [.init(value: "15.0.1")],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/champions/search?name=willump"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "matches": [
            [
              "champion": [
                "id": "nunu",
                "imageUrl": imageUrl("Nunu"),
                "name": "Nunu & Willump",
              ],
              "availableIn": ["regular"],
            ]
          ]
        ]
      )
    }
  }

  func testMultipleRotationTypes() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-21T12:00:00Z")!,
          champions: ["Sett", "Nocturne", "Rengar"],
          slug: "s1w1",
        )
      ],
      dbBeginnerRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          maxLevel: 10,
          champions: ["Sett", "Nocturne", "Senna"]
        )
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
        .init(id: uuid("2"), riotId: "Sett", name: "Sett"),
        .init(id: uuid("3"), riotId: "Rengar", name: "Rengar"),
        .init(id: uuid("4"), riotId: "Senna", name: "Senna"),
      ],
      dbPatchVersions: [.init(value: "15.0.1")],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/champions/search?name=se"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "matches": [
            [
              "champion": [
                "id": "senna",
                "imageUrl": imageUrl("Senna"),
                "name": "Senna",
              ],
              "availableIn": ["beginner"],
            ],
            [
              "champion": [
                "id": "sett",
                "imageUrl": imageUrl("Sett"),
                "name": "Sett",
              ],
              "availableIn": ["regular", "beginner"],
            ],
          ]
        ]
      )
    }
  }

  func testChampionMatchesOrder() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [],
      dbBeginnerRotations: [],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Elise", name: "Elise"),
        .init(id: uuid("2"), riotId: "Sett", name: "Sett"),
        .init(id: uuid("3"), riotId: "Mordekaiser", name: "Mordekaiser"),
        .init(id: uuid("4"), riotId: "Senna", name: "Senna"),
      ],
      dbPatchVersions: [.init(value: "15.0.1")],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/champions/search?name=se"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "matches": [
            [
              "champion": [
                "id": "senna",
                "imageUrl": imageUrl("Senna"),
                "name": "Senna",
              ],
              "availableIn": [],
            ],
            [
              "champion": [
                "id": "sett",
                "imageUrl": imageUrl("Sett"),
                "name": "Sett",
              ],
              "availableIn": [],
            ],
            [
              "champion": [
                "id": "elise",
                "imageUrl": imageUrl("Elise"),
                "name": "Elise",
              ],
              "availableIn": [],
            ],
            [
              "champion": [
                "id": "mordekaiser",
                "imageUrl": imageUrl("Mordekaiser"),
                "name": "Mordekaiser",
              ],
              "availableIn": [],
            ],
          ]
        ]
      )
    }
  }
}
