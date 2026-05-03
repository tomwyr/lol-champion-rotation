import Testing

@testable import App

extension AppTests {
  @Suite(.serialized) struct NextRotationsPageTests {
    @Test(.serialized, arguments: appAccessTokens)
    func noPageParam(accessToken: String) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
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
          .GET, "/rotations/paged",
          headers: reqHeaders(accessToken: accessToken),
        ) { res async throws in
          #expect(res.status == .badRequest)
        }
      }
    }

    @Test(.serialized, arguments: appAccessTokens)
    func noRotations(accessToken: String) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/paged?page=1&count=2",
          headers: reqHeaders(accessToken: accessToken),
        ) { res async throws in
          #expect(res.status == .notFound)
        }
      }
    }

    @Test(.serialized, arguments: appAccessTokens)
    func singlePage(accessToken: String) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Garen"],
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
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/paged?page=1&count=2",
          headers: reqHeaders(accessToken: accessToken),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "entries": [
                [
                  "id": "s1w2",
                  "current": true,
                  "duration": [
                    "start": "2024-11-15T12:00:00Z",
                    "end": "2024-11-21T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "nocturne",
                      "name": "Nocturne",
                      "imageUrl":
                        "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Nocturne.jpg",
                    ]
                  ],
                ],
                [
                  "id": "s1w1",
                  "current": false,
                  "duration": [
                    "start": "2024-11-14T12:00:00Z",
                    "end": "2024-11-15T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "garen",
                      "name": "Garen",
                      "imageUrl":
                        "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Garen.jpg",
                    ]
                  ],
                ],
              ],
              "hasNext": false,
            ],
          )
        }
      }
    }

    @Test(.serialized, arguments: appAccessTokens)
    func singlePageWithNextPage(accessToken: String) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Garen"],
              slug: "s1w1",
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-15T12:00:00Z")!,
              champions: ["Nocturne"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("3"),
              observedAt: .iso("2024-11-16T12:00:00Z")!,
              champions: ["Sett"],
              slug: "s1w3",
            ),
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/paged?page=1&count=2",
          headers: reqHeaders(accessToken: accessToken),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "entries": [
                [
                  "id": "s1w3",
                  "current": true,
                  "duration": [
                    "start": "2024-11-16T12:00:00Z",
                    "end": "2024-11-21T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "sett",
                      "name": "Sett",
                      "imageUrl":
                        "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Sett.jpg",
                    ]
                  ],
                ],
                [
                  "id": "s1w2",
                  "current": false,
                  "duration": [
                    "start": "2024-11-15T12:00:00Z",
                    "end": "2024-11-16T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "nocturne",
                      "name": "Nocturne",
                      "imageUrl":
                        "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Nocturne.jpg",
                    ]
                  ],
                ],
              ],
              "hasNext": true,
            ],
          )
        }
      }
    }

    @Test(.serialized, arguments: appAccessTokens)
    func outOfBoundPage(accessToken: String) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Garen"],
              slug: "s1w1",
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-15T12:00:00Z")!,
              champions: ["Nocturne"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("3"),
              observedAt: .iso("2024-11-16T12:00:00Z")!,
              champions: ["Sett"],
              slug: "s1w3",
            ),
            .init(
              id: uuid("4"),
              observedAt: .iso("2024-11-17T12:00:00Z")!,
              champions: ["Sett"],
              slug: "s1w4",
            ),
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
            .init(id: uuid("4"), riotId: "Senna", name: "Senna"),
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/paged?page=3&count=2",
          headers: reqHeaders(accessToken: accessToken),
        ) { res async throws in
          #expect(res.status == .notFound)
        }
      }
    }

    @Test(.serialized, arguments: appAccessTokens)
    func partialPage(accessToken: String) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Garen"],
              slug: "s1w1",
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-15T12:00:00Z")!,
              champions: ["Nocturne"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("3"),
              observedAt: .iso("2024-11-16T12:00:00Z")!,
              champions: ["Sett"],
              slug: "s1w3",
            ),
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
            .init(id: uuid("4"), riotId: "Senna", name: "Senna"),
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/paged?page=2&count=2",
          headers: reqHeaders(accessToken: accessToken),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "entries": [
                [
                  "id": "s1w1",
                  "current": false,
                  "duration": [
                    "start": "2024-11-14T12:00:00Z",
                    "end": "2024-11-15T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "garen",
                      "name": "Garen",
                      "imageUrl":
                        "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Garen.jpg",
                    ]
                  ],
                ]
              ],
              "hasNext": false,
            ],
          )
        }
      }
    }

    @Test(.serialized, arguments: appAccessTokens)
    func subsequentPage(accessToken: String) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Garen"],
              slug: "s1w1",
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-15T12:00:00Z")!,
              champions: ["Nocturne"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("3"),
              observedAt: .iso("2024-11-16T12:00:00Z")!,
              champions: ["Sett"],
              slug: "s1w3",
            ),
            .init(
              id: uuid("4"),
              observedAt: .iso("2024-11-17T12:00:00Z")!,
              champions: ["Sett"],
              slug: "s1w4",
            ),
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
            .init(id: uuid("4"), riotId: "Senna", name: "Senna"),
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/paged?page=2&count=2",
          headers: reqHeaders(accessToken: accessToken),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "entries": [
                [
                  "id": "s1w2",
                  "current": false,
                  "duration": [
                    "start": "2024-11-15T12:00:00Z",
                    "end": "2024-11-16T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "nocturne",
                      "name": "Nocturne",
                      "imageUrl":
                        "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Nocturne.jpg",
                    ]
                  ],
                ],
                [
                  "id": "s1w1",
                  "current": false,
                  "duration": [
                    "start": "2024-11-14T12:00:00Z",
                    "end": "2024-11-15T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "garen",
                      "name": "Garen",
                      "imageUrl":
                        "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Garen.jpg",
                    ]
                  ],
                ],
              ],
              "hasNext": false,
            ],
          )
        }
      }
    }

    @Test(.serialized, arguments: appAccessTokens)
    func subsequentPageWithNextPage(accessToken: String) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Garen"],
              slug: "s1w1",
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-15T12:00:00Z")!,
              champions: ["Nocturne"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("3"),
              observedAt: .iso("2024-11-16T12:00:00Z")!,
              champions: ["Sett"],
              slug: "s1w3",
            ),
            .init(
              id: uuid("4"),
              observedAt: .iso("2024-11-17T12:00:00Z")!,
              champions: ["Sett"],
              slug: "s1w4",
            ),
            .init(
              id: uuid("5"),
              observedAt: .iso("2024-11-18T12:00:00Z")!,
              champions: ["Diana"],
              slug: "s1w5",
            ),
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
            .init(id: uuid("4"), riotId: "Senna", name: "Senna"),
            .init(id: uuid("5"), riotId: "Diana", name: "Diana"),
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/paged?page=2&count=2",
          headers: reqHeaders(accessToken: accessToken),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "entries": [
                [
                  "id": "s1w3",
                  "current": false,
                  "duration": [
                    "start": "2024-11-16T12:00:00Z",
                    "end": "2024-11-17T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "sett",
                      "name": "Sett",
                      "imageUrl":
                        "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Sett.jpg",
                    ]
                  ],
                ],
                [
                  "id": "s1w2",
                  "current": false,
                  "duration": [
                    "start": "2024-11-15T12:00:00Z",
                    "end": "2024-11-16T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "nocturne",
                      "name": "Nocturne",
                      "imageUrl":
                        "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Nocturne.jpg",
                    ]
                  ],
                ],
              ],
              "hasNext": true,
            ],
          )
        }
      }
    }

    @Test(.serialized, arguments: appAccessTokens)
    func subsequentHistoricalPage(accessToken: String) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Garen"],
              slug: "s1w1",
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-15T12:00:00Z")!,
              champions: ["Nocturne"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("3"),
              observedAt: .iso("2024-11-16T12:00:00Z")!,
              champions: ["Sett"],
              slug: "s1w3",
            ),
            .init(
              id: uuid("4"),
              observedAt: .iso("2024-11-17T12:00:00Z")!,
              champions: ["Sett"],
              slug: "s1w4",
            ),
            .init(
              id: uuid("5"),
              observedAt: .iso("2024-11-18T12:00:00Z")!,
              champions: ["Diana"],
              slug: "s1w5",
            ),
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
            .init(id: uuid("4"), riotId: "Senna", name: "Senna"),
            .init(id: uuid("5"), riotId: "Diana", name: "Diana"),
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/paged?page=2&count=2&historical=true",
          headers: reqHeaders(accessToken: accessToken),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "entries": [
                [
                  "id": "s1w2",
                  "current": false,
                  "duration": [
                    "start": "2024-11-15T12:00:00Z",
                    "end": "2024-11-16T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "nocturne",
                      "name": "Nocturne",
                      "imageUrl":
                        "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Nocturne.jpg",
                    ]
                  ],
                ],
                [
                  "id": "s1w1",
                  "current": false,
                  "duration": [
                    "start": "2024-11-14T12:00:00Z",
                    "end": "2024-11-15T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "garen",
                      "name": "Garen",
                      "imageUrl":
                        "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Garen.jpg",
                    ]
                  ],
                ],
              ],
              "hasNext": false,
            ],
          )
        }
      }
    }
  }
}
