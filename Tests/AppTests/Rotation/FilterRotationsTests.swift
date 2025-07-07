import XCTVapor

@testable import App

class FilterRotationsTests: AppTests {
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
      .GET, "/rotations/search"
    ) { res async in
      XCTAssertEqual(res.status, .badRequest)
    }
  }

  func testNoMatchingRotations() async throws {
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
      .GET, "/rotations/search?championName=Nocturne"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "regularRotations": []
        ]
      )
    }
  }

  func testRotationWithExactMatch() async throws {
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
      .GET, "/rotations/search?championName=Nocturne"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "regularRotations": [
            [
              "duration": [
                "start": "2024-11-14T12:00:00Z",
                "end": "2024-11-21T12:00:00Z",
              ],
              "champions": [
                [
                  "id": "nocturne",
                  "imageUrl": imageUrl("Nocturne"),
                  "name": "Nocturne",
                ]
              ],
              "current": true,
            ]
          ]
        ]
      )
    }
  }

  func testRotationWithNonExactMatch() async throws {
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
      .GET, "/rotations/search?championName=oCtuRn"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "regularRotations": [
            [
              "duration": [
                "start": "2024-11-14T12:00:00Z",
                "end": "2024-11-21T12:00:00Z",
              ],
              "champions": [
                [
                  "id": "nocturne",
                  "imageUrl": imageUrl("Nocturne"),
                  "name": "Nocturne",
                ]
              ],
              "current": true,
            ]
          ]
        ]
      )
    }
  }

  func testRotationWithMultipleMatches() async throws {
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
      .GET, "/rotations/search?championName=En"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "regularRotations": [
            [
              "duration": [
                "start": "2024-11-14T12:00:00Z",
                "end": "2024-11-21T12:00:00Z",
              ],
              "champions": [
                [
                  "id": "garen",
                  "imageUrl": imageUrl("Garen"),
                  "name": "Garen",
                ],
                [
                  "id": "rengar",
                  "imageUrl": imageUrl("Rengar"),
                  "name": "Rengar",
                ],
              ],
              "current": true,
            ]
          ]
        ]
      )
    }
  }

  func testRotationWithMatchesInMultipleRotations() async throws {
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
        .init(
          id: uuid("3"),
          observedAt: .iso("2024-11-07T12:00:00Z")!,
          champions: ["Sett", "Nocturne", "Samira"],
          slug: "s1w3",
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
      .GET, "/rotations/search?championName=En"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "regularRotations": [
            [
              "duration": [
                "start": "2024-11-21T12:00:00Z",
                "end": "2024-11-28T12:00:00Z",
              ],
              "champions": [
                [
                  "id": "rengar",
                  "imageUrl": imageUrl("Rengar"),
                  "name": "Rengar",
                ]
              ],
              "current": true,
            ],
            [
              "duration": [
                "start": "2024-11-14T12:00:00Z",
                "end": "2024-11-21T12:00:00Z",
              ],
              "champions": [
                [
                  "id": "garen",
                  "imageUrl": imageUrl("Garen"),
                  "name": "Garen",
                ],
                [
                  "id": "rengar",
                  "imageUrl": imageUrl("Rengar"),
                  "name": "Rengar",
                ],
              ],
              "current": false,
            ],
          ]
        ]
      )
    }
  }

  func testRotationWithMatchInNameOnly() async throws {
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
      .GET, "/rotations/search?championName=willump"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "regularRotations": [
            [
              "duration": [
                "start": "2024-11-14T12:00:00Z",
                "end": "2024-11-21T12:00:00Z",
              ],
              "champions": [
                [
                  "id": "nunu",
                  "imageUrl": imageUrl("Nunu"),
                  "name": "Nunu & Willump",
                ]
              ],
              "current": true,
            ]
          ]
        ]
      )
    }
  }

  func testRotationsOrderedByDate() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-07T12:00:00Z")!,
          champions: ["Sett"],
          slug: "s1w1",
        ),
        .init(
          id: uuid("2"),
          observedAt: .iso("2024-11-21T12:00:00Z")!,
          champions: ["Sett"],
          slug: "s1w2",
        ),
        .init(
          id: uuid("3"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Sett"],
          slug: "s1w3",
        ),
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Sett", name: "Sett")
      ],
      dbPatchVersions: [.init(value: "15.0.1")],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/rotations/search?championName=sett"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "regularRotations": [
            [
              "duration": [
                "start": "2024-11-21T12:00:00Z",
                "end": "2024-11-28T12:00:00Z",
              ],
              "champions": [
                [
                  "id": "sett",
                  "imageUrl": imageUrl("Sett"),
                  "name": "Sett",
                ]
              ],
              "current": true,
            ],
            [
              "duration": [
                "start": "2024-11-14T12:00:00Z",
                "end": "2024-11-21T12:00:00Z",
              ],
              "champions": [
                [
                  "id": "sett",
                  "imageUrl": imageUrl("Sett"),
                  "name": "Sett",
                ]
              ],
              "current": false,
            ],
            [
              "duration": [
                "start": "2024-11-07T12:00:00Z",
                "end": "2024-11-14T12:00:00Z",
              ],
              "champions": [
                [
                  "id": "sett",
                  "imageUrl": imageUrl("Sett"),
                  "name": "Sett",
                ]
              ],
              "current": false,
            ],
          ]
        ]
      )
    }
  }

  func testBeginnerRotation() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbBeginnerRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          maxLevel: 10,
          champions: ["Garen", "Nocturne", "Vi"]
        ),
        .init(
          id: uuid("2"),
          observedAt: .iso("2024-11-21T12:00:00Z")!,
          maxLevel: 10,
          champions: ["Garen", "Zoe", "Diana"]
        ),
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
        .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
        .init(id: uuid("3"), riotId: "Vi", name: "Vi"),
        .init(id: uuid("4"), riotId: "Zoe", name: "Zoe"),
        .init(id: uuid("5"), riotId: "Diana", name: "Diana"),
      ],
      dbPatchVersions: [.init(value: "15.0.1")],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/rotations/search?championName=dia"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "regularRotations": [],
          "beginnerRotation": [
            "champions": [
              [
                "id": "diana",
                "imageUrl": imageUrl("Diana"),
                "name": "Diana",
              ]
            ]
          ],
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
      .GET, "/rotations/search?championName=se"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "regularRotations": [
            [
              "duration": [
                "start": "2024-11-21T12:00:00Z",
                "end": "2024-11-28T12:00:00Z",
              ],
              "champions": [
                [
                  "id": "sett",
                  "imageUrl": imageUrl("Sett"),
                  "name": "Sett",
                ]
              ],
              "current": true,
            ]
          ],
          "beginnerRotation": [
            "champions": [
              [
                "id": "sett",
                "imageUrl": imageUrl("Sett"),
                "name": "Sett",
              ],
              [
                "id": "senna",
                "imageUrl": imageUrl("Senna"),
                "name": "Senna",
              ],
            ]
          ],
        ]
      )
    }
  }
}
