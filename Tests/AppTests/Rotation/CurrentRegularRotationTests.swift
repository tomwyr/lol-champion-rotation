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
          champions: ["Garen", "Sett"],
          slug: "s1w1",
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
          "id": "s1w1",
          "duration": [
            "start": "2024-11-14T12:00:00Z",
            "end": "2024-11-21T12:00:00Z",
          ],
          "champions": [
            [
              "id": "garen",
              "name": "Garen",
              "imageUrl": imageUrl("Garen"),
            ],
            [
              "id": "sett",
              "name": "Sett",
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
          champions: ["Jax", "Sett", "Garen"],
          slug: "s1w1",
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
          ["id": "garen", "name": "Garen", "imageUrl": imageUrl("Garen")],
          ["id": "jax", "name": "Jax", "imageUrl": imageUrl("Jax")],
          ["id": "sett", "name": "Sett", "imageUrl": imageUrl("Sett")],
        ]
      )
    }
  }
}
