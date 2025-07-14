import Testing

@testable import App

extension AppTests {
  @Suite(.serialized) struct NextRotationTests {
    @Test func noTokenParam() async throws {
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

    @Test func noNextRotation() async throws {
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
          .GET, "/rotations?nextRotationToken=\(nextRotationToken("1"))"
        ) { res async throws in
          #expect(res.status == .notFound)
        }
      }
    }

    @Test func unknownPreviousRotation() async throws {
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
          .GET, "/rotations?nextRotationToken=\(nextRotationToken("1"))"
        ) { res async throws in
          #expect(res.status == .notFound)
        }
      }
    }

    @Test func rotationWithNoNextToken() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Garen", "Sett"],
              slug: "s1w1",
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-15T12:00:00Z")!,
              champions: ["Nocturne"],
              slug: "s1w2",
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
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "id": "s1w1",
              "patchVersion": "15.0.1",
              "duration": [
                "start": "2024-11-14T12:00:00Z",
                "end": "2024-11-15T12:00:00Z",
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

    @Test func rotationWithNextToken() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-13T12:00:00Z")!,
              champions: ["Nocturne", "Sett"],
              slug: "s1w1",
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Garen", "Sett"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("3"),
              observedAt: .iso("2024-11-15T12:00:00Z")!,
              champions: ["Nocturne"],
              slug: "s1w3",
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
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "id": "s1w2",
              "nextRotationToken": nextRotationToken("2"),
              "patchVersion": "15.0.1",
              "duration": [
                "start": "2024-11-14T12:00:00Z",
                "end": "2024-11-15T12:00:00Z",
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

    @Test func inactiveRotation() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-13T12:00:00Z")!,
              champions: ["Nocturne", "Sett"],
              slug: "s1w1",
            ),
            .init(
              id: uuid("2"),
              active: false,
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Garen", "Sett"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("3"),
              observedAt: .iso("2024-11-15T12:00:00Z")!,
              champions: ["Nocturne"],
              slug: "s1w3",
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
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "id": "s1w1",
              "patchVersion": "15.0.1",
              "duration": [
                "start": "2024-11-13T12:00:00Z",
                "end": "2024-11-15T12:00:00Z",
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
              "current": false,
            ]
          )
        }
      }
    }
  }
}
