import Testing

@testable import App

extension AppTests {
  @Suite(.serialized) struct FilterRotationsTests {
    @Test func noQueryParam() async throws {
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
          .GET, "/rotations/search"
        ) { res async throws in
          #expect(res.status == .badRequest)
        }
      }
    }

    @Test func noMatchingRotations() async throws {
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
          .GET, "/rotations/search?championName=Nocturne"
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "regularRotations": []
            ]
          )
        }
      }
    }

    @Test func rotationWithExactMatch() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Garen", "Sett", "Nocturne"],
              slug: "s1w1",
            )
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
          .GET, "/rotations/search?championName=Nocturne"
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "regularRotations": [
                [
                  "duration": [
                    "start": "2024-11-14T12:00:00Z",
                    "end": "2024-11-21T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "nocturne",
                      "imageUrl": imageUrl("Nocturne"),
                      "name": "Nocturne",
                    ]
                  ],
                  "current": true,
                ]
              ]
            ]
          )
        }
      }
    }

    @Test func rotationWithNonExactMatch() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Garen", "Sett", "Nocturne"],
              slug: "s1w1",
            )
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
          .GET, "/rotations/search?championName=oCtuRn"
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "regularRotations": [
                [
                  "duration": [
                    "start": "2024-11-14T12:00:00Z",
                    "end": "2024-11-21T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "nocturne",
                      "imageUrl": imageUrl("Nocturne"),
                      "name": "Nocturne",
                    ]
                  ],
                  "current": true,
                ]
              ]
            ]
          )
        }
      }
    }

    @Test func rotationWithMultipleMatches() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Garen", "Sett", "Nocturne", "Rengar"],
              slug: "s1w1",
            )
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
            .init(id: uuid("4"), riotId: "Rengar", name: "Rengar"),
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/search?championName=En"
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "regularRotations": [
                [
                  "duration": [
                    "start": "2024-11-14T12:00:00Z",
                    "end": "2024-11-21T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "garen",
                      "imageUrl": imageUrl("Garen"),
                      "name": "Garen",
                    ],
                    [
                      "id": "rengar",
                      "imageUrl": imageUrl("Rengar"),
                      "name": "Rengar",
                    ],
                  ],
                  "current": true,
                ]
              ]
            ]
          )
        }
      }
    }

    @Test func rotationWithMatchesInMultipleRotations() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-21T12:00:00Z")!,
              champions: ["Sett", "Nocturne", "Rengar"],
              slug: "s1w1",
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Garen", "Sett", "Rengar"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("3"),
              observedAt: .iso("2024-11-07T12:00:00Z")!,
              champions: ["Sett", "Nocturne", "Samira"],
              slug: "s1w3",
            ),
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
            .init(id: uuid("4"), riotId: "Rengar", name: "Rengar"),
            .init(id: uuid("5"), riotId: "Samira", name: "Samira"),
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/search?championName=En"
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "regularRotations": [
                [
                  "duration": [
                    "start": "2024-11-21T12:00:00Z",
                    "end": "2024-11-28T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "rengar",
                      "imageUrl": imageUrl("Rengar"),
                      "name": "Rengar",
                    ]
                  ],
                  "current": true,
                ],
                [
                  "duration": [
                    "start": "2024-11-14T12:00:00Z",
                    "end": "2024-11-21T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "garen",
                      "imageUrl": imageUrl("Garen"),
                      "name": "Garen",
                    ],
                    [
                      "id": "rengar",
                      "imageUrl": imageUrl("Rengar"),
                      "name": "Rengar",
                    ],
                  ],
                  "current": false,
                ],
              ]
            ]
          )
        }
      }
    }

    @Test func rotationWithMatchInNameOnly() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Sett", "Nocturne", "Nunu"],
              slug: "s1w1",
            )
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Nunu", name: "Nunu & Willump"),
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/search?championName=willump"
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "regularRotations": [
                [
                  "duration": [
                    "start": "2024-11-14T12:00:00Z",
                    "end": "2024-11-21T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "nunu",
                      "imageUrl": imageUrl("Nunu"),
                      "name": "Nunu & Willump",
                    ]
                  ],
                  "current": true,
                ]
              ]
            ]
          )
        }
      }
    }

    @Test func rotationsOrderedByDate() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-07T12:00:00Z")!,
              champions: ["Sett"],
              slug: "s1w1",
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-21T12:00:00Z")!,
              champions: ["Sett"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("3"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Sett"],
              slug: "s1w3",
            ),
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Sett", name: "Sett")
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/search?championName=sett"
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "regularRotations": [
                [
                  "duration": [
                    "start": "2024-11-21T12:00:00Z",
                    "end": "2024-11-28T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "sett",
                      "imageUrl": imageUrl("Sett"),
                      "name": "Sett",
                    ]
                  ],
                  "current": true,
                ],
                [
                  "duration": [
                    "start": "2024-11-14T12:00:00Z",
                    "end": "2024-11-21T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "sett",
                      "imageUrl": imageUrl("Sett"),
                      "name": "Sett",
                    ]
                  ],
                  "current": false,
                ],
                [
                  "duration": [
                    "start": "2024-11-07T12:00:00Z",
                    "end": "2024-11-14T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "sett",
                      "imageUrl": imageUrl("Sett"),
                      "name": "Sett",
                    ]
                  ],
                  "current": false,
                ],
              ]
            ]
          )
        }
      }
    }

    @Test func beginnerRotation() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbBeginnerRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              maxLevel: 10,
              champions: ["Garen", "Nocturne", "Vi"]
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-21T12:00:00Z")!,
              maxLevel: 10,
              champions: ["Garen", "Zoe", "Diana"]
            ),
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Vi", name: "Vi"),
            .init(id: uuid("4"), riotId: "Zoe", name: "Zoe"),
            .init(id: uuid("5"), riotId: "Diana", name: "Diana"),
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/search?championName=dia"
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "regularRotations": [],
              "beginnerRotation": [
                "champions": [
                  [
                    "id": "diana",
                    "imageUrl": imageUrl("Diana"),
                    "name": "Diana",
                  ]
                ]
              ],
            ]
          )
        }
      }
    }

    @Test func multipleRotationTypes() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-21T12:00:00Z")!,
              champions: ["Sett", "Nocturne", "Rengar"],
              slug: "s1w1",
            )
          ],
          dbBeginnerRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              maxLevel: 10,
              champions: ["Sett", "Nocturne", "Senna"]
            )
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Sett", name: "Sett"),
            .init(id: uuid("3"), riotId: "Rengar", name: "Rengar"),
            .init(id: uuid("4"), riotId: "Senna", name: "Senna"),
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/search?championName=se"
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "regularRotations": [
                [
                  "duration": [
                    "start": "2024-11-21T12:00:00Z",
                    "end": "2024-11-28T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "sett",
                      "imageUrl": imageUrl("Sett"),
                      "name": "Sett",
                    ]
                  ],
                  "current": true,
                ]
              ],
              "beginnerRotation": [
                "champions": [
                  [
                    "id": "sett",
                    "imageUrl": imageUrl("Sett"),
                    "name": "Sett",
                  ],
                  [
                    "id": "senna",
                    "imageUrl": imageUrl("Senna"),
                    "name": "Senna",
                  ],
                ]
              ],
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
              observedAt: .iso("2024-11-21T12:00:00Z")!,
              champions: ["Sett", "Nocturne", "Rengar"],
              slug: "s1w1",
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Garen", "Sett", "Rengar"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("3"),
              observedAt: .iso("2024-11-07T12:00:00Z")!,
              champions: ["Sett", "Nocturne", "Samira"],
              slug: "s1w3",
            ),
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Sett", name: "Sett"),
            .init(id: uuid("4"), riotId: "Rengar", name: "Rengar"),
            .init(id: uuid("5"), riotId: "Samira", name: "Samira"),
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/rotations/search?championName=En"
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "regularRotations": [
                [
                  "duration": [
                    "start": "2024-11-14T12:00:00Z",
                    "end": "2024-11-21T12:00:00Z",
                  ],
                  "champions": [
                    [
                      "id": "garen",
                      "imageUrl": imageUrl("Garen"),
                      "name": "Garen",
                    ],
                    [
                      "id": "rengar",
                      "imageUrl": imageUrl("Rengar"),
                      "name": "Rengar",
                    ],
                  ],
                  "current": true,
                ]
              ]
            ]
          )
        }
      }
    }
  }
}
