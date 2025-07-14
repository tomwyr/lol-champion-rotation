import Foundation
import Testing

@testable import App

extension AppTests {
  @Suite(.serialized) struct CurrentRegularRotationTests {
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
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
          ],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/current"
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
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
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

    @Test func inactiveRotation() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("2"),
              active: false,
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Garen", "Sett"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-07T12:00:00Z")!,
              champions: ["Nocturne", "Sett"],
              slug: "s1w1",
            ),
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
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "id": "s1w1",
              "duration": [
                "start": "2024-11-07T12:00:00Z",
                "end": "2024-11-14T12:00:00Z",
              ],
              "champions": [
                [
                  "id": "nocturne",
                  "name": "Nocturne",
                  "imageUrl": imageUrl("Nocturne"),
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
  }
}
