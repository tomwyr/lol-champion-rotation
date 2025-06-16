import XCTVapor

@testable import App

class CurrentRegularRotationTests: AppTests {
  func testSimpleResult() async throws {
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
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/rotations/current"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "id": uuidString("1"),
          "duration": [
            "start": "2024-11-14T12:00:00Z",
            "end": "2024-11-21T12:00:00Z",
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
        ]
      )
    }
  }

  func testChampionsAreSortedById() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          observedAt: Date.now,
          champions: ["Jax", "Sett", "Garen"]
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
      .GET, "/rotations/current"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body, at: "champions",
        [
          ["id": uuidString("4"), "name": "Garen", "imageUrl": imageUrl("Garen")],
          ["id": uuidString("5"), "name": "Jax", "imageUrl": imageUrl("Jax")],
          ["id": uuidString("6"), "name": "Sett", "imageUrl": imageUrl("Sett")],
        ]
      )
    }
  }
}
