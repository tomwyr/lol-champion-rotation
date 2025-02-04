import XCTVapor

@testable import App

class CurrentRotationTests: AppTests {
  func testSimpleResult() async throws {
    _ = try await testConfigureWith(
      idHasherSecretKey: idHasherSecretKey,
      idHasherNonce: idHasherNonce,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Garen", "Sett"]
        )
      ],
      dbBeginnerRotations: [
        .init(
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          maxLevel: 10,
          champions: ["Nocturne"]
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
      .GET, "/rotation/current"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "patchVersion": "15.0.1",
          "duration": [
            "start": "2024-11-14T12:00:00Z",
            "end": "2024-11-28T12:00:00Z",
          ],
          "beginnerMaxLevel": 10,
          "beginnerChampions": [
            [
              "id": uuidString("1"), "name": "Nocturne",
              "imageUrl": imageUrl("Nocturne"),
            ]
          ],
          "regularChampions": [
            [
              "id": uuidString("2"), "name": "Garen",
              "imageUrl": imageUrl("Garen"),
            ],
            [
              "id": uuidString("3"), "name": "Sett",
              "imageUrl": imageUrl("Sett"),
            ],
          ],
        ]
      )
    }
  }

  func testChampionsAreSortedById() async throws {
    _ = try await testConfigureWith(
      idHasherSecretKey: idHasherSecretKey,
      idHasherNonce: idHasherNonce,
      dbRegularRotations: [
        .init(
          observedAt: Date.now,
          champions: ["Jax", "Sett", "Garen"]
        )
      ],
      dbBeginnerRotations: [
        .init(
          observedAt: Date.now,
          maxLevel: 10,
          champions: ["Nocturne", "Ashe", "Shen"]
        )
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Ashe", name: "Ashe"),
        .init(id: uuid("2"), riotId: "Nocturne", name: "Nocturne"),
        .init(id: uuid("3"), riotId: "Shen", name: "Shen"),
        .init(id: uuid("4"), riotId: "Garen", name: "Garen"),
        .init(id: uuid("5"), riotId: "Jax", name: "Jax"),
        .init(id: uuid("6"), riotId: "Sett", name: "Sett"),
      ],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/rotation/current"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body, at: "beginnerChampions",
        [
          ["id": uuidString("1"), "name": "Ashe", "imageUrl": imageUrl("Ashe")],
          ["id": uuidString("2"), "name": "Nocturne", "imageUrl": imageUrl("Nocturne")],
          ["id": uuidString("3"), "name": "Shen", "imageUrl": imageUrl("Shen")],
        ]
      )
      XCTAssertBody(
        res.body, at: "regularChampions",
        [
          ["id": uuidString("4"), "name": "Garen", "imageUrl": imageUrl("Garen")],
          ["id": uuidString("5"), "name": "Jax", "imageUrl": imageUrl("Jax")],
          ["id": uuidString("6"), "name": "Sett", "imageUrl": imageUrl("Sett")],
        ]
      )
    }
  }

  func testSameChampionIsBeginnerAndRegular() async throws {
    _ = try await testConfigureWith(
      idHasherSecretKey: idHasherSecretKey,
      idHasherNonce: idHasherNonce,
      dbRegularRotations: [
        .init(
          observedAt: Date.now,
          champions: ["Nocturne", "Sett"]
        )
      ],
      dbBeginnerRotations: [
        .init(
          observedAt: Date.now,
          maxLevel: 10,
          champions: ["Garen", "Sett"]
        )
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Garen", name: "Garen"),
        .init(id: uuid("2"), riotId: "Sett", name: "Sett"),
        .init(id: uuid("3"), riotId: "Nocturne", name: "Nocturne"),
      ],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/rotation/current"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body, at: "beginnerChampions",
        [
          ["id": uuidString("1"), "name": "Garen", "imageUrl": imageUrl("Garen")],
          ["id": uuidString("2"), "name": "Sett", "imageUrl": imageUrl("Sett")],
        ]
      )
      XCTAssertBody(
        res.body, at: "regularChampions",
        [
          ["id": uuidString("3"), "name": "Nocturne", "imageUrl": imageUrl("Nocturne")],
          ["id": uuidString("2"), "name": "Sett", "imageUrl": imageUrl("Sett")],
        ]
      )
    }
  }

  func testOptionalDataUnavailable() async throws {
    _ = try await testConfigureWith(
      idHasherSecretKey: idHasherSecretKey,
      idHasherNonce: idHasherNonce,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: []
        )
      ],
      dbBeginnerRotations: [
        .init(
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          maxLevel: 10,
          champions: []
        )
      ],
      dbChampions: [],
      dbPatchVersions: []
    )

    try await app.test(
      .GET, "/rotation/current"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "duration": [
            "start": "2024-11-14T12:00:00Z",
            "end": "2024-11-28T12:00:00Z",
          ],
          "beginnerMaxLevel": 10,
          "beginnerChampions": [],
          "regularChampions": [],
        ]
      )
    }
  }

  func testNoNextRotation() async throws {
    _ = try await testConfigureWith(
      idHasherSecretKey: idHasherSecretKey,
      idHasherNonce: idHasherNonce,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: []
        )
      ],
      dbBeginnerRotations: [
        .init(
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          maxLevel: 10,
          champions: []
        )
      ],
      dbChampions: [],
      dbPatchVersions: []
    )

    try await app.test(
      .GET, "/rotation/current"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "duration": [
            "start": "2024-11-14T12:00:00Z",
            "end": "2024-11-28T12:00:00Z",
          ],
          "beginnerMaxLevel": 10,
          "beginnerChampions": [],
          "regularChampions": [],
        ]
      )
    }
  }

  func testSingleNextRotation() async throws {
    _ = try await testConfigureWith(
      idHasherSecretKey: idHasherSecretKey,
      idHasherNonce: idHasherNonce,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-13T12:00:00Z")!,
          champions: []
        ),
        .init(
          id: uuid("2"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: []
        ),
      ],
      dbBeginnerRotations: [
        .init(
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          maxLevel: 10,
          champions: []
        )
      ],
      dbChampions: [],
      dbPatchVersions: []
    )

    try await app.test(
      .GET, "/rotation/current"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "nextRotationToken": nextRotationToken("2"),
          "duration": [
            "start": "2024-11-14T12:00:00Z",
            "end": "2024-11-28T12:00:00Z",
          ],
          "beginnerMaxLevel": 10,
          "beginnerChampions": [],
          "regularChampions": [],
        ]
      )
    }
  }

  func testMultipleNextRotations() async throws {
    _ = try await testConfigureWith(
      idHasherSecretKey: idHasherSecretKey,
      idHasherNonce: idHasherNonce,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-11T12:00:00Z")!,
          champions: []
        ),
        .init(
          id: uuid("2"),
          observedAt: .iso("2024-11-12T12:00:00Z")!,
          champions: []
        ),
        .init(
          id: uuid("3"),
          observedAt: .iso("2024-11-13T12:00:00Z")!,
          champions: []
        ),
        .init(
          id: uuid("4"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: []
        ),
      ],
      dbBeginnerRotations: [
        .init(
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          maxLevel: 10,
          champions: []
        )
      ],
      dbChampions: [],
      dbPatchVersions: []
    )

    try await app.test(
      .GET, "/rotation/current"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "nextRotationToken": nextRotationToken("4"),
          "duration": [
            "start": "2024-11-14T12:00:00Z",
            "end": "2024-11-28T12:00:00Z",
          ],
          "beginnerMaxLevel": 10,
          "beginnerChampions": [],
          "regularChampions": [],
        ]
      )
    }
  }
}
