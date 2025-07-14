import Testing

@testable import App

extension AppTests {
  @Suite(.serialized) struct RotationTests {
    @Test func noIdParam() async throws {
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
          dbPatchVersions: [.init(value: "15.0.1")],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations"
        ) { res async throws in
          #expect(res.status == .badRequest)
        }
      }
    }

    @Test func unknownRotation() async throws {
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
          dbPatchVersions: [.init(value: "15.0.1")],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/s1w2"
        ) { res async throws in
          #expect(res.status == .notFound)
        }
      }
    }

    @Test func currentRotation() async throws {
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
          dbPatchVersions: [.init(observedAt: .iso("2024-11-10T12:00:00Z")!, value: "15.0.1")],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/s1w1"
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
              "current": true,
            ]
          )
        }
      }
    }

    @Test func nonCurrentRotation() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-21T12:00:00Z")!,
              champions: ["Nocturne", "Sett"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Garen", "Sett"],
              slug: "s1w1",
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
          .GET, "/rotations/s1w1"
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
              "current": false,
            ]
          )
        }
      }
    }

    @Test func userObservingRotation() async throws {
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
          dbPatchVersions: [.init(observedAt: .iso("2024-11-10T12:00:00Z")!, value: "15.0.1")],
          dbUserWatchlists: [
            .init(userId: mobileUserId, rotations: [uuidString("1")])
          ],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/s1w1",
          headers: reqHeaders(accessToken: mobileToken)
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "id": "s1w1",
              "observing": true,
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
              "current": true,
            ]
          )
        }
      }
    }

    @Test func userNotObservingRotation() async throws {
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
          dbPatchVersions: [.init(observedAt: .iso("2024-11-10T12:00:00Z")!, value: "15.0.1")],
          dbUserWatchlists: [
            .init(userId: mobileUserId, rotations: [uuidString("2")])
          ],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/s1w1",
          headers: reqHeaders(accessToken: mobileToken)
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "id": "s1w1",
              "observing": false,
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
              "current": true,
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
              id: uuid("1"),
              active: false,
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
          dbPatchVersions: [.init(observedAt: .iso("2024-11-10T12:00:00Z")!, value: "15.0.1")],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/s1w1"
        ) { res async throws in
          #expect(res.status == .notFound)
        }
      }
    }
  }
}
