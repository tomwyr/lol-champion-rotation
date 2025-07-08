import Foundation
import Testing

@testable import App

extension AppTests {
  @Suite(.serialized) struct RotationsOverviewTests {
    @Test func simpleResult() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Garen", "Sett"],
              slug: "s1w1",
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
          .GET, "/rotations/overview"
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "id": "s1w1",
              "patchVersion": "15.0.1",
              "duration": [
                "start": "2024-11-14T12:00:00Z",
                "end": "2024-11-21T12:00:00Z",
              ],
              "beginnerMaxLevel": 10,
              "beginnerChampions": [
                [
                  "id": "nocturne",
                  "name": "Nocturne",
                  "imageUrl": imageUrl("Nocturne"),
                ]
              ],
              "regularChampions": [
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
    }

    @Test func championsAreSortedById() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              observedAt: Date.now,
              champions: ["Jax", "Sett", "Garen"],
              slug: "s1w1",
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
          .GET, "/rotations/overview"
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body, at: "beginnerChampions",
            [
              ["id": "ashe", "name": "Ashe", "imageUrl": imageUrl("Ashe")],
              ["id": "nocturne", "name": "Nocturne", "imageUrl": imageUrl("Nocturne")],
              ["id": "shen", "name": "Shen", "imageUrl": imageUrl("Shen")],
            ]
          )
          try expectBody(
            res.body, at: "regularChampions",
            [
              ["id": "garen", "name": "Garen", "imageUrl": imageUrl("Garen")],
              ["id": "jax", "name": "Jax", "imageUrl": imageUrl("Jax")],
              ["id": "sett", "name": "Sett", "imageUrl": imageUrl("Sett")],
            ]
          )
        }
      }
    }

    @Test func sameChampionIsBeginnerAndRegular() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              observedAt: Date.now,
              champions: ["Nocturne", "Sett"],
              slug: "s1w1",
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
          .GET, "/rotations/overview"
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body, at: "beginnerChampions",
            [
              ["id": "garen", "name": "Garen", "imageUrl": imageUrl("Garen")],
              ["id": "sett", "name": "Sett", "imageUrl": imageUrl("Sett")],
            ]
          )
          try expectBody(
            res.body, at: "regularChampions",
            [
              ["id": "nocturne", "name": "Nocturne", "imageUrl": imageUrl("Nocturne")],
              ["id": "sett", "name": "Sett", "imageUrl": imageUrl("Sett")],
            ]
          )
        }
      }
    }

    @Test func optionalDataUnavailable() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: [],
              slug: "s1w1",
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
          .GET, "/rotations/overview"
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "id": "s1w1",
              "duration": [
                "start": "2024-11-14T12:00:00Z",
                "end": "2024-11-21T12:00:00Z",
              ],
              "beginnerMaxLevel": 10,
              "beginnerChampions": [],
              "regularChampions": [],
            ]
          )
        }
      }
    }

    @Test func noNextRotation() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: [],
              slug: "s1w1",
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
          .GET, "/rotations/overview"
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "id": "s1w1",
              "duration": [
                "start": "2024-11-14T12:00:00Z",
                "end": "2024-11-21T12:00:00Z",
              ],
              "beginnerMaxLevel": 10,
              "beginnerChampions": [],
              "regularChampions": [],
            ]
          )
        }
      }
    }

    @Test func singleNextRotation() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-13T12:00:00Z")!,
              champions: [],
              slug: "s1w1"
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: [],
              slug: "s1w2"
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
          .GET, "/rotations/overview"
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "id": "s1w2",
              "nextRotationToken": nextRotationToken("2"),
              "duration": [
                "start": "2024-11-14T12:00:00Z",
                "end": "2024-11-21T12:00:00Z",
              ],
              "beginnerMaxLevel": 10,
              "beginnerChampions": [],
              "regularChampions": [],
            ]
          )
        }
      }
    }

    @Test func multipleNextRotations() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-11T12:00:00Z")!,
              champions: [],
              slug: "s1w1"
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-12T12:00:00Z")!,
              champions: [],
              slug: "s1w2"
            ),
            .init(
              id: uuid("3"),
              observedAt: .iso("2024-11-13T12:00:00Z")!,
              champions: [],
              slug: "s1w3"
            ),
            .init(
              id: uuid("4"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: [],
              slug: "s1w4"
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
          .GET, "/rotations/overview"
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "id": "s1w4",
              "nextRotationToken": nextRotationToken("4"),
              "duration": [
                "start": "2024-11-14T12:00:00Z",
                "end": "2024-11-21T12:00:00Z",
              ],
              "beginnerMaxLevel": 10,
              "beginnerChampions": [],
              "regularChampions": [],
            ]
          )
        }
      }
    }
  }
}
