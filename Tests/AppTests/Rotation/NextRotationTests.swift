import Testing

@testable import App

extension AppTests {
  @Suite(.serialized) struct NextRotationTests {
    @Test func noTokenParam() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appWebKey: webApiKey,
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
          .GET, "/rotations",
          headers: reqHeaders(accessToken: webApiKey),
        ) { res async throws in
          #expect(res.status == .badRequest)
        }
      }
    }

    @Test func noNextRotation() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appWebKey: webApiKey,
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
          .GET, "/rotations?nextRotationToken=\(nextRotationToken("1"))",
          headers: reqHeaders(accessToken: webApiKey),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(res.body, [])
        }
      }
    }

    @Test func unknownPreviousRotation() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appWebKey: webApiKey,
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
          .GET, "/rotations?nextRotationToken=\(nextRotationToken("1"))",
          headers: reqHeaders(accessToken: webApiKey),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(res.body, [])
        }
      }
    }

    @Test func rotationWithNoNextToken() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appWebKey: webApiKey,
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
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations?nextRotationToken=\(nextRotationToken("2"))",
          headers: reqHeaders(accessToken: webApiKey),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
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
            ]
          )
        }
      }
    }

    @Test func rotationWithNextToken() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appWebKey: webApiKey,
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
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations?nextRotationToken=\(nextRotationToken("3"))",
          headers: reqHeaders(accessToken: webApiKey),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
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
            ]
          )
        }
      }
    }

    @Test func inactiveRotation() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appWebKey: webApiKey,
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
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations?nextRotationToken=\(nextRotationToken("3"))",
          headers: reqHeaders(accessToken: webApiKey),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
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
            ]
          )
        }
      }
    }

    @Test func multipleRotationsWithNextToken() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appWebKey: webApiKey,
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
            .init(
              id: uuid("4"),
              observedAt: .iso("2024-11-16T12:00:00Z")!,
              champions: ["Garen", "Senna"],
              slug: "s1w4",
            ),
            .init(
              id: uuid("5"),
              observedAt: .iso("2024-11-17T12:00:00Z")!,
              champions: ["Fiora"],
              slug: "s1w5",
            ),
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
            .init(id: uuid("4"), riotId: "Senna", name: "Senna"),
            .init(id: uuid("5"), riotId: "Fiora", name: "Fiora"),
          ],
          dbPatchVersions: [
            .init(
              observedAt: .iso("2024-11-01T12:00:00Z"),
              value: "15.0.1"
            )
          ],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations?nextRotationToken=\(nextRotationToken("5"))&count=3",
          headers: reqHeaders(accessToken: webApiKey),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              [
                "id": "s1w4",
                "nextRotationToken": nextRotationToken("4"),
                "patchVersion": "15.0.1",
                "duration": [
                  "start": "2024-11-16T12:00:00Z",
                  "end": "2024-11-17T12:00:00Z",
                ],
                "champions": [
                  [
                    "id": "garen",
                    "name": "Garen",
                    "imageUrl": imageUrl("Garen"),
                  ],
                  [
                    "id": "senna",
                    "name": "Senna",
                    "imageUrl": imageUrl("Senna"),
                  ],
                ],
                "current": false,
              ],
              [
                "id": "s1w3",
                "nextRotationToken": nextRotationToken("3"),
                "patchVersion": "15.0.1",
                "duration": [
                  "start": "2024-11-15T12:00:00Z",
                  "end": "2024-11-16T12:00:00Z",
                ],
                "champions": [
                  [
                    "id": "nocturne",
                    "name": "Nocturne",
                    "imageUrl": imageUrl("Nocturne"),
                  ]
                ],
                "current": false,
              ],
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
              ],
            ]
          )
        }
      }
    }

    @Test func multipleRotationsWithNoNextToken() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appWebKey: webApiKey,
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
            .init(
              id: uuid("4"),
              observedAt: .iso("2024-11-16T12:00:00Z")!,
              champions: ["Garen", "Senna"],
              slug: "s1w4",
            ),
            .init(
              id: uuid("5"),
              observedAt: .iso("2024-11-17T12:00:00Z")!,
              champions: ["Fiora"],
              slug: "s1w5",
            ),
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
            .init(id: uuid("4"), riotId: "Senna", name: "Senna"),
            .init(id: uuid("5"), riotId: "Fiora", name: "Fiora"),
          ],
          dbPatchVersions: [
            .init(
              observedAt: .iso("2024-11-01T12:00:00Z"),
              value: "15.0.1"
            )
          ],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations?nextRotationToken=\(nextRotationToken("4"))&count=3",
          headers: reqHeaders(accessToken: webApiKey),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              [
                "id": "s1w3",
                "nextRotationToken": nextRotationToken("3"),
                "patchVersion": "15.0.1",
                "duration": [
                  "start": "2024-11-15T12:00:00Z",
                  "end": "2024-11-16T12:00:00Z",
                ],
                "champions": [
                  [
                    "id": "nocturne",
                    "name": "Nocturne",
                    "imageUrl": imageUrl("Nocturne"),
                  ]
                ],
                "current": false,
              ],
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
              ],
              [
                "id": "s1w1",
                "patchVersion": "15.0.1",
                "duration": [
                  "start": "2024-11-13T12:00:00Z",
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
                "current": false,
              ],
            ]
          )
        }
      }
    }

    @Test func multipleRotationsExceedingAvailableCount() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appWebKey: webApiKey,
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
            .init(
              id: uuid("4"),
              observedAt: .iso("2024-11-16T12:00:00Z")!,
              champions: ["Garen", "Senna"],
              slug: "s1w4",
            ),
            .init(
              id: uuid("5"),
              observedAt: .iso("2024-11-17T12:00:00Z")!,
              champions: ["Fiora"],
              slug: "s1w5",
            ),
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
            .init(id: uuid("4"), riotId: "Senna", name: "Senna"),
            .init(id: uuid("5"), riotId: "Fiora", name: "Fiora"),
          ],
          dbPatchVersions: [
            .init(
              observedAt: .iso("2024-11-01T12:00:00Z"),
              value: "15.0.1"
            )
          ],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations?nextRotationToken=\(nextRotationToken("4"))&count=100",
          headers: reqHeaders(accessToken: webApiKey),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              [
                "id": "s1w3",
                "nextRotationToken": nextRotationToken("3"),
                "patchVersion": "15.0.1",
                "duration": [
                  "start": "2024-11-15T12:00:00Z",
                  "end": "2024-11-16T12:00:00Z",
                ],
                "champions": [
                  [
                    "id": "nocturne",
                    "name": "Nocturne",
                    "imageUrl": imageUrl("Nocturne"),
                  ]
                ],
                "current": false,
              ],
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
              ],
              [
                "id": "s1w1",
                "patchVersion": "15.0.1",
                "duration": [
                  "start": "2024-11-13T12:00:00Z",
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
                "current": false,
              ],
            ]
          )
        }
      }
    }

    @Test func multipleRotationsWithInvalidCount() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appWebKey: webApiKey,
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
            .init(
              id: uuid("4"),
              observedAt: .iso("2024-11-16T12:00:00Z")!,
              champions: ["Garen", "Senna"],
              slug: "s1w4",
            ),
            .init(
              id: uuid("5"),
              observedAt: .iso("2024-11-17T12:00:00Z")!,
              champions: ["Fiora"],
              slug: "s1w5",
            ),
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
            .init(id: uuid("4"), riotId: "Senna", name: "Senna"),
            .init(id: uuid("5"), riotId: "Fiora", name: "Fiora"),
          ],
          dbPatchVersions: [
            .init(
              observedAt: .iso("2024-11-01T12:00:00Z"),
              value: "15.0.1"
            )
          ],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations?nextRotationToken=\(nextRotationToken("4"))&count=-1",
          headers: reqHeaders(accessToken: webApiKey),
        ) { res async throws in
          #expect(res.status == .badRequest)
        }
      }
    }

    @Test func multipleRotationsWithZeroCount() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appWebKey: webApiKey,
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
            .init(
              id: uuid("4"),
              observedAt: .iso("2024-11-16T12:00:00Z")!,
              champions: ["Garen", "Senna"],
              slug: "s1w4",
            ),
            .init(
              id: uuid("5"),
              observedAt: .iso("2024-11-17T12:00:00Z")!,
              champions: ["Fiora"],
              slug: "s1w5",
            ),
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
            .init(id: uuid("4"), riotId: "Senna", name: "Senna"),
            .init(id: uuid("5"), riotId: "Fiora", name: "Fiora"),
          ],
          dbPatchVersions: [
            .init(
              observedAt: .iso("2024-11-01T12:00:00Z"),
              value: "15.0.1"
            )
          ],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations?nextRotationToken=\(nextRotationToken("4"))&count=0",
          headers: reqHeaders(accessToken: webApiKey),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(res.body, [])
        }
      }
    }
  }
}
