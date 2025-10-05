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
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
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
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
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
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
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

    @Test func twoRotationsInSingleWeek() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appManagementKey: "123",
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .isoDate("2025-09-15")!,
              champions: ["Ahri", "Aurora", "Belveth"],
              slug: "s15w36",
            ),
            .init(
              id: uuid("2"),
              observedAt: .isoDate("2025-09-22")!,
              champions: ["Akshan", "Azir", "Ekko"],
              slug: "s15w37",
            ),
            .init(
              id: uuid("3"),
              observedAt: .isoDate("2025-09-29")!,
              champions: ["Alistar", "AurelionSol", "Illaoi"],
              slug: "s15w38",
            ),
            .init(
              id: uuid("4"),
              observedAt: .isoDate("2025-10-02")!,
              champions: ["Ahri", "Annie", "Aurora", "Belveth"],
              slug: "s15w38-2",
            ),
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Ahri", name: "Ahri"),
            .init(id: uuid("2"), riotId: "Annie", name: "Annie"),
            .init(id: uuid("3"), riotId: "Aurora", name: "Aurora"),
            .init(id: uuid("4"), riotId: "Belveth", name: "Belveth"),
          ],
          dbPatchVersions: [
            .init(observedAt: .isoDate("2025-09-24")!, value: "15.19.1"),
            .init(observedAt: .isoDate("2025-09-10")!, value: "15.18.1"),
            .init(observedAt: .isoDate("2025-08-27")!, value: "15.17.1"),
            .init(observedAt: .isoDate("2025-01-09")!, value: "15.1.1"),
          ],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 1)],
        )

        try await app.test(
          .GET, "/rotations/current"
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "id": "s15w38-2",
              "duration": [
                "start": "2025-10-02T00:00:00Z",
                "end": "2025-10-06T00:00:00Z",
              ],
              "champions": [
                [
                  "id": "ahri",
                  "name": "Ahri",
                  "imageUrl": imageUrl("Ahri"),
                ],
                [
                  "id": "annie",
                  "name": "Annie",
                  "imageUrl": imageUrl("Annie"),
                ],
                [
                  "id": "aurora",
                  "name": "Aurora",
                  "imageUrl": imageUrl("Aurora"),
                ],
                [
                  "id": "belveth",
                  "name": "Belveth",
                  "imageUrl": imageUrl("Belveth"),
                ],
              ],
            ]
          )
        }
      }
    }
  }
}
