import XCTVapor

@testable import App

class CurrentRotationTests: AppTests {
  func testSimpleResult() async throws {
    _ = try await testConfigureWith(
      dbChampionRotation: .init(
        observedAt: .iso("2024-11-14T12:00:00Z"),
        beginnerMaxLevel: 10,
        beginnerChampions: ["Nocturne"],
        regularChampions: ["Garen", "Sett"]
      ),
      dbChampions: [
        .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
        .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
        .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
      ],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/api/rotation/current"
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
          "beginnerChampions": [
            [
              "id": id("1"), "name": "Nocturne",
              "imageUrl": imageUrl("Nocturne"),
            ]
          ],
          "regularChampions": [
            [
              "id": id("2"), "name": "Garen",
              "imageUrl": imageUrl("Garen"),
            ],
            [
              "id": id("3"), "name": "Sett",
              "imageUrl": imageUrl("Sett"),
            ],
          ],
        ]
      )
    }
  }

  func testChampionsAreSortedById() async throws {
    _ = try await testConfigureWith(
      dbChampionRotation: .init(
        beginnerMaxLevel: 10,
        beginnerChampions: ["Nocturne", "Ashe", "Shen"],
        regularChampions: ["Jax", "Sett", "Garen"]
      ),
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
      .GET, "/api/rotation/current"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body, at: "beginnerChampions",
        [
          ["id": id("1"), "name": "Ashe", "imageUrl": imageUrl("Ashe")],
          ["id": id("2"), "name": "Nocturne", "imageUrl": imageUrl("Nocturne")],
          ["id": id("3"), "name": "Shen", "imageUrl": imageUrl("Shen")],
        ]
      )
      XCTAssertBody(
        res.body, at: "regularChampions",
        [
          ["id": id("4"), "name": "Garen", "imageUrl": imageUrl("Garen")],
          ["id": id("5"), "name": "Jax", "imageUrl": imageUrl("Jax")],
          ["id": id("6"), "name": "Sett", "imageUrl": imageUrl("Sett")],
        ]
      )
    }
  }

  func testSameChampionIsBeginnerAndRegular() async throws {
    _ = try await testConfigureWith(
      dbChampionRotation: .init(
        beginnerMaxLevel: 10,
        beginnerChampions: ["Garen", "Sett"],
        regularChampions: ["Nocturne", "Sett"]
      ),
      dbChampions: [
        .init(id: uuid("1"), riotId: "Garen", name: "Garen"),
        .init(id: uuid("2"), riotId: "Sett", name: "Sett"),
        .init(id: uuid("3"), riotId: "Nocturne", name: "Nocturne"),
      ],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/api/rotation/current"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body, at: "beginnerChampions",
        [
          ["id": id("1"), "name": "Garen", "imageUrl": imageUrl("Garen")],
          ["id": id("2"), "name": "Sett", "imageUrl": imageUrl("Sett")],
        ]
      )
      XCTAssertBody(
        res.body, at: "regularChampions",
        [
          ["id": id("3"), "name": "Nocturne", "imageUrl": imageUrl("Nocturne")],
          ["id": id("2"), "name": "Sett", "imageUrl": imageUrl("Sett")],
        ]
      )
    }
  }
}

func imageUrl(_ championId: String) -> String {
  "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/\(championId).jpg"
}

func uuid(_ value: String) -> UUID? {
  UUID(id(value))
}

func id(_ value: String) -> String {
  "00000000-0000-0000-0000-00000000000\(value)"
}
