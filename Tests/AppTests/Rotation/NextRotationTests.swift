import XCTVapor

@testable import App

class NextRotationTests: AppTests {
  func testNoTokenParam() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Garen", "Sett"]
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
      .GET, "/rotations"
    ) { res async in
      XCTAssertEqual(res.status, .badRequest)
    }
  }

  func testNoNextRotation() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Garen", "Sett"]
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
      .GET, "/rotations?nextRotationToken=\(nextRotationToken("1"))"
    ) { res async in
      XCTAssertEqual(res.status, .notFound)
    }
  }

  func testUnknownPreviousRotation() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Garen", "Sett"]
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
      .GET, "/rotations?nextRotationToken=\(nextRotationToken("1"))"
    ) { res async in
      XCTAssertEqual(res.status, .notFound)
    }
  }

  func testRotationWithNoNextToken() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Garen", "Sett"]
        ),
        .init(
          id: uuid("2"),
          observedAt: .iso("2024-11-15T12:00:00Z")!,
          champions: ["Nocturne"]
        ),
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
        .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
        .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
      ],
      dbPatchVersions: [
        .init(
          observedAt: .iso("2024-11-01T12:00:00Z"),
          value: "15.0.1"
        )
      ],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/rotations?nextRotationToken=\(nextRotationToken("2"))"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "patchVersion": "15.0.1",
          "duration": [
            "start": "2024-11-14T12:00:00Z",
            "end": "2024-11-15T12:00:00Z",
          ],
          "champions": [
            [
              "id": uuidString("2"), "name": "Garen",
              "imageUrl": imageUrl("Garen"),
            ],
            [
              "id": uuidString("3"), "name": "Sett",
              "imageUrl": imageUrl("Sett"),
            ],
          ],
          "current": false,
        ]
      )
    }
  }

  func testRotationWithNextToken() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-13T12:00:00Z")!,
          champions: ["Nocturne", "Sett"]
        ),
        .init(
          id: uuid("2"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Garen", "Sett"]
        ),
        .init(
          id: uuid("3"),
          observedAt: .iso("2024-11-15T12:00:00Z")!,
          champions: ["Nocturne"]
        ),
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
        .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
        .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
      ],
      dbPatchVersions: [
        .init(
          observedAt: .iso("2024-11-01T12:00:00Z"),
          value: "15.0.1"
        )
      ],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/rotations?nextRotationToken=\(nextRotationToken("3"))"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "nextRotationToken": nextRotationToken("2"),
          "patchVersion": "15.0.1",
          "duration": [
            "start": "2024-11-14T12:00:00Z",
            "end": "2024-11-15T12:00:00Z",
          ],
          "champions": [
            [
              "id": uuidString("2"), "name": "Garen",
              "imageUrl": imageUrl("Garen"),
            ],
            [
              "id": uuidString("3"), "name": "Sett",
              "imageUrl": imageUrl("Sett"),
            ],
          ],
          "current": false,
        ]
      )
    }
  }
}
