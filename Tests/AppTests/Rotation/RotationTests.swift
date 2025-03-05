import XCTVapor

@testable import App

class RotationTests: AppTests {
  func testNoIdParam() async throws {
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

  func testUnknownRotation() async throws {
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
      .GET, "/rotations/\(uuidString("2"))"
    ) { res async in
      XCTAssertEqual(res.status, .notFound)
    }
  }

  func testCurrentRotation() async throws {
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
      dbPatchVersions: [.init(observedAt: .iso("2024-11-10T12:00:00Z")!, value: "15.0.1")],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/rotations/\(uuidString("1"))"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "patchVersion": "15.0.1",
          "duration": [
            "start": "2024-11-14T12:00:00Z",
            "end": "2024-11-21T12:00:00Z",
          ],
          "champions": [
            [
              "id": uuidString("2"),
              "name": "Garen",
              "imageUrl": imageUrl("Garen"),
            ],
            [
              "id": uuidString("3"),
              "name": "Sett",
              "imageUrl": imageUrl("Sett"),
            ],
          ],
          "current": true,
        ]
      )
    }
  }

  func testNonCurrentRotation() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          id: uuid("2"),
          observedAt: .iso("2024-11-21T12:00:00Z")!,
          champions: ["Nocturne", "Sett"]
        ),
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: ["Garen", "Sett"]
        ),
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
        .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
        .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
      ],
      dbPatchVersions: [.init(observedAt: .iso("2024-11-10T12:00:00Z")!, value: "15.0.1")],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/rotations/\(uuidString("1"))"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "patchVersion": "15.0.1",
          "duration": [
            "start": "2024-11-14T12:00:00Z",
            "end": "2024-11-21T12:00:00Z",
          ],
          "champions": [
            [
              "id": uuidString("2"),
              "name": "Garen",
              "imageUrl": imageUrl("Garen"),
            ],
            [
              "id": uuidString("3"),
              "name": "Sett",
              "imageUrl": imageUrl("Sett"),
            ],
          ],
          "current": false,
        ]
      )
    }
  }
}
