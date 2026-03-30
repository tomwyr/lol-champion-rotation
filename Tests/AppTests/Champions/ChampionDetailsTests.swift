import Testing
import VaporTestUtils

@testable import App

extension AppTests {
  @Suite(.serialized) struct ChampionDetailsTests {
    @Test(.serialized, arguments: appAccessTokens)
    func unknownChampion(accessToken: String) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbChampions: [
            .init(
              id: uuid("1"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Nocturne",
              name: "Nocturne", title: "the Eternal Nightmare")
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/champions/Garen",
          headers: reqHeaders(accessToken: accessToken),
        ) { res async throws in
          #expect(res.status == .notFound)
        }
      }
    }

    @Test func knownChampionMobile() async throws {
      try await knownChampionMobile(accessToken: mobileAccessToken) { res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "observing": false,
            "availability": [
              [
                "rotationType": "regular",
                "current": false,
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 0,
              "popularity": 1,
              "currentStreak": 0,
            ],
            "history": [
              [
                "type": "release",
                "releasedAt": "2024-01-01T00:00:00Z",
              ]
            ],
          ]
        )
      }
    }

    @Test func knownChampionWeb() async throws {
      try await knownChampionMobile(accessToken: webApiKey) { res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "availability": [
              [
                "rotationType": "regular",
                "current": false,
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 0,
              "popularity": 1,
              "currentStreak": 0,
            ],
            "history": [
              [
                "type": "release",
                "releasedAt": "2024-01-01T00:00:00Z",
              ]
            ],
          ]
        )
      }
    }

    func knownChampionMobile(
      accessToken: String,
      afterResponse: (TestingHTTPResponse) async throws -> Void,
    ) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbChampions: [
            .init(
              id: uuid("1"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Nocturne",
              name: "Nocturne", title: "the Eternal Nightmare")
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/champions/Nocturne",
          headers: reqHeaders(accessToken: accessToken),
          afterResponse: afterResponse,
        )
      }
    }

    @Test func knownChampionCaseInsensitiveMobile() async throws {
      try await knownChampionCaseInsensitive(accessToken: mobileAccessToken) { res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "observing": false,
            "availability": [
              [
                "rotationType": "regular",
                "current": false,
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 0,
              "popularity": 1,
              "currentStreak": 0,
            ],
            "history": [
              [
                "type": "release",
                "releasedAt": "2024-01-01T00:00:00Z",
              ]
            ],
          ]
        )
      }
    }

    @Test func knownChampionCaseInsensitiveWeb() async throws {
      try await knownChampionCaseInsensitive(accessToken: webApiKey) { res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "availability": [
              [
                "rotationType": "regular",
                "current": false,
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 0,
              "popularity": 1,
              "currentStreak": 0,
            ],
            "history": [
              [
                "type": "release",
                "releasedAt": "2024-01-01T00:00:00Z",
              ]
            ],
          ]
        )
      }
    }

    func knownChampionCaseInsensitive(
      accessToken: String,
      afterResponse: (TestingHTTPResponse) async throws -> Void,
    ) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbChampions: [
            .init(
              id: uuid("1"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Nocturne",
              name: "Nocturne", title: "the Eternal Nightmare")
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/champions/nocturne",
          headers: reqHeaders(accessToken: accessToken),
          afterResponse: afterResponse,
        )
      }
    }

    @Test func championWithMissingReleaseDateMobile() async throws {
      try await championWithMissingReleaseDate(accessToken: mobileAccessToken) { res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "observing": false,
            "availability": [
              [
                "rotationType": "regular",
                "current": false,
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 0
            ],
            "history": [],
          ],
        )
      }
    }

    @Test func championWithMissingReleaseDateWeb() async throws {
      try await championWithMissingReleaseDate(accessToken: webApiKey) { res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "availability": [
              [
                "rotationType": "regular",
                "current": false,
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 0
            ],
            "history": [],
          ],
        )
      }
    }

    func championWithMissingReleaseDate(
      accessToken: String,
      afterResponse: (TestingHTTPResponse) async throws -> Void,
    ) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbChampions: [
            .init(
              id: uuid("1"), riotId: "Nocturne",
              name: "Nocturne", title: "the Eternal Nightmare")
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/champions/Nocturne",
          headers: reqHeaders(accessToken: accessToken),
          afterResponse: afterResponse,
        )
      }
    }

    @Test func championInCurrentRotationMobile() async throws {
      try await championInCurrentRotationMobile(accessToken: mobileAccessToken) {
        res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "observing": false,
            "availability": [
              [
                "rotationType": "regular",
                "current": true,
                "lastAvailable": "2024-11-14T12:00:00Z",
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 1,
              "popularity": 1,
              "currentStreak": 1,
            ],
            "history": [
              [
                "type": "rotation",
                "id": "s1w1",
                "duration": [
                  "start": "2024-11-14T12:00:00Z",
                  "end": "2024-11-21T12:00:00Z",
                ],
                "current": true,
                "championImageUrls": [imageUrl("Nocturne")],
              ],
              [
                "type": "release",
                "releasedAt": "2024-01-01T00:00:00Z",
              ],
            ],
          ]
        )
      }
    }

    @Test func championInCurrentRotationWeb() async throws {
      try await championInCurrentRotationMobile(accessToken: webApiKey) { res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "availability": [
              [
                "rotationType": "regular",
                "current": true,
                "lastAvailable": "2024-11-14T12:00:00Z",
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 1,
              "popularity": 1,
              "currentStreak": 1,
            ],
            "history": [
              [
                "type": "rotation",
                "id": "s1w1",
                "duration": [
                  "start": "2024-11-14T12:00:00Z",
                  "end": "2024-11-21T12:00:00Z",
                ],
                "current": true,
                "championImageUrls": [imageUrl("Nocturne")],
              ],
              [
                "type": "release",
                "releasedAt": "2024-01-01T00:00:00Z",
              ],
            ],
          ]
        )
      }
    }

    func championInCurrentRotationMobile(
      accessToken: String,
      afterResponse: (TestingHTTPResponse) async throws -> Void,
    ) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Nocturne"],
              slug: "s1w1",
            )
          ],
          dbChampions: [
            .init(
              id: uuid("1"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Nocturne",
              name: "Nocturne", title: "the Eternal Nightmare")
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123"),
        )

        try await app.test(
          .GET, "/champions/Nocturne",
          headers: reqHeaders(accessToken: accessToken),
          afterResponse: afterResponse,
        )
      }
    }

    @Test func championInPreviousRotationMobile() async throws {
      try await championInPreviousRotation(accessToken: mobileAccessToken) { res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "observing": false,
            "availability": [
              [
                "rotationType": "regular",
                "current": false,
              ],
              [
                "rotationType": "beginner",
                "current": true,
                "lastAvailable": "2024-11-14T12:00:00Z",
              ],
            ],
            "overview": [
              "occurrences": 0,
              "popularity": 1,
              "currentStreak": 0,
            ],
            "history": [
              [
                "type": "release",
                "releasedAt": "2024-01-01T00:00:00Z",
              ]
            ],
          ]
        )
      }
    }

    @Test func championInPreviousRotationWeb() async throws {
      try await championInPreviousRotation(accessToken: webApiKey) { res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "availability": [
              [
                "rotationType": "regular",
                "current": false,
              ],
              [
                "rotationType": "beginner",
                "current": true,
                "lastAvailable": "2024-11-14T12:00:00Z",
              ],
            ],
            "overview": [
              "occurrences": 0,
              "popularity": 1,
              "currentStreak": 0,
            ],
            "history": [
              [
                "type": "release",
                "releasedAt": "2024-01-01T00:00:00Z",
              ]
            ],
          ]
        )
      }
    }

    func championInPreviousRotation(
      accessToken: String,
      afterResponse: (TestingHTTPResponse) async throws -> Void,
    ) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbBeginnerRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!, maxLevel: 10,
              champions: ["Nocturne"]
            )
          ],
          dbChampions: [
            .init(
              id: uuid("1"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Nocturne",
              name: "Nocturne", title: "the Eternal Nightmare")
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/champions/Nocturne",
          headers: reqHeaders(accessToken: accessToken),
          afterResponse: afterResponse,
        )
      }
    }

    @Test func overviewWithPositiveStreakMobile() async throws {
      try await overviewWithPositiveStreak(accessToken: mobileAccessToken) { res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "observing": false,
            "availability": [
              [
                "rotationType": "regular",
                "current": true,
                "lastAvailable": "2024-11-14T12:00:00Z",
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 3,
              "popularity": 2,
              "currentStreak": 2,
            ],
            "history": [
              [
                "type": "rotation",
                "id": "s1w4",
                "duration": [
                  "start": "2024-11-14T12:00:00Z",
                  "end": "2024-11-21T12:00:00Z",
                ],
                "current": true,
                "championImageUrls": [
                  imageUrl("Senna"),
                  imageUrl("Nocturne"),
                ],
              ],
              [
                "type": "rotation",
                "id": "s1w3",
                "duration": [
                  "start": "2024-11-13T12:00:00Z",
                  "end": "2024-11-14T12:00:00Z",
                ],
                "current": false,
                "championImageUrls": [
                  imageUrl("Nocturne"),
                  imageUrl("Fiora"),
                  imageUrl("Senna"),
                ],
              ],
              [
                "type": "bench",
                "rotationsMissed": 1,
              ],
              [
                "type": "rotation",
                "id": "s1w1",
                "duration": [
                  "start": "2024-11-11T12:00:00Z",
                  "end": "2024-11-12T12:00:00Z",
                ],
                "current": false,
                "championImageUrls": [
                  imageUrl("Nocturne"),
                  imageUrl("Fiora"),
                  imageUrl("Senna"),
                ],
              ],
              [
                "type": "release",
                "releasedAt": "2024-01-01T00:00:00Z",
              ],
            ],
          ]
        )
      }
    }

    @Test func overviewWithPositiveStreakWeb() async throws {
      try await overviewWithPositiveStreak(accessToken: webApiKey) { res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "availability": [
              [
                "rotationType": "regular",
                "current": true,
                "lastAvailable": "2024-11-14T12:00:00Z",
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 3,
              "popularity": 2,
              "currentStreak": 2,
            ],
            "history": [
              [
                "type": "rotation",
                "id": "s1w4",
                "duration": [
                  "start": "2024-11-14T12:00:00Z",
                  "end": "2024-11-21T12:00:00Z",
                ],
                "current": true,
                "championImageUrls": [
                  imageUrl("Senna"),
                  imageUrl("Nocturne"),
                ],
              ],
              [
                "type": "rotation",
                "id": "s1w3",
                "duration": [
                  "start": "2024-11-13T12:00:00Z",
                  "end": "2024-11-14T12:00:00Z",
                ],
                "current": false,
                "championImageUrls": [
                  imageUrl("Nocturne"),
                  imageUrl("Fiora"),
                  imageUrl("Senna"),
                ],
              ],
              [
                "type": "bench",
                "rotationsMissed": 1,
              ],
              [
                "type": "rotation",
                "id": "s1w1",
                "duration": [
                  "start": "2024-11-11T12:00:00Z",
                  "end": "2024-11-12T12:00:00Z",
                ],
                "current": false,
                "championImageUrls": [
                  imageUrl("Nocturne"),
                  imageUrl("Fiora"),
                  imageUrl("Senna"),
                ],
              ],
              [
                "type": "release",
                "releasedAt": "2024-01-01T00:00:00Z",
              ],
            ],
          ]
        )
      }
    }

    func overviewWithPositiveStreak(
      accessToken: String,
      afterResponse: (TestingHTTPResponse) async throws -> Void,
    ) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("4"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Nocturne", "Senna"],
              slug: "s1w4",
            ),
            .init(
              id: uuid("3"),
              observedAt: .iso("2024-11-13T12:00:00Z")!,
              champions: ["Nocturne", "Senna", "Fiora"],
              slug: "s1w3",
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-12T12:00:00Z")!,
              champions: ["Senna"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-11T12:00:00Z")!,
              champions: ["Nocturne", "Senna", "Fiora"],
              slug: "s1w1",
            ),
          ],
          dbChampions: [
            .init(
              id: uuid("1"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Nocturne",
              name: "Nocturne", title: "the Eternal Nightmare"),
            .init(
              id: uuid("2"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Senna",
              name: "Senna",
              title: "the Redeemer"),
            .init(
              id: uuid("3"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Fiora",
              name: "Fiora",
              title: "the Grand Duelist"),
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/champions/Nocturne",
          headers: reqHeaders(accessToken: accessToken),
          afterResponse: afterResponse,
        )
      }
    }

    @Test func overviewWithNegativeStreakMobile() async throws {
      try await overviewWithNegativeStreak(accessToken: mobileAccessToken) { res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "observing": false,
            "availability": [
              [
                "rotationType": "regular",
                "current": false,
                "lastAvailable": "2024-11-12T12:00:00Z",
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 1,
              "popularity": 3,
              "currentStreak": -2,
            ],
            "history": [
              [
                "type": "bench",
                "rotationsMissed": 2,
              ],
              [
                "type": "rotation",
                "id": "s1w2",
                "duration": [
                  "start": "2024-11-12T12:00:00Z",
                  "end": "2024-11-13T12:00:00Z",
                ],
                "current": false,
                "championImageUrls": [
                  imageUrl("Senna"),
                  imageUrl("Nocturne"),
                ],
              ],
              [
                "type": "bench",
                "rotationsMissed": 1,
              ],
              [
                "type": "release",
                "releasedAt": "2024-01-01T00:00:00Z",
              ],
            ],
          ]
        )
      }
    }

    @Test func overviewWithNegativeStreakWeb() async throws {
      try await overviewWithNegativeStreak(accessToken: webApiKey) { res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "availability": [
              [
                "rotationType": "regular",
                "current": false,
                "lastAvailable": "2024-11-12T12:00:00Z",
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 1,
              "popularity": 3,
              "currentStreak": -2,
            ],
            "history": [
              [
                "type": "bench",
                "rotationsMissed": 2,
              ],
              [
                "type": "rotation",
                "id": "s1w2",
                "duration": [
                  "start": "2024-11-12T12:00:00Z",
                  "end": "2024-11-13T12:00:00Z",
                ],
                "current": false,
                "championImageUrls": [
                  imageUrl("Senna"),
                  imageUrl("Nocturne"),
                ],
              ],
              [
                "type": "bench",
                "rotationsMissed": 1,
              ],
              [
                "type": "release",
                "releasedAt": "2024-01-01T00:00:00Z",
              ],
            ],
          ]
        )
      }
    }

    func overviewWithNegativeStreak(
      accessToken: String,
      afterResponse: (TestingHTTPResponse) async throws -> Void,
    ) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("4"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Senna", "Fiora"],
              slug: "s1w4",
            ),
            .init(
              id: uuid("3"),
              observedAt: .iso("2024-11-13T12:00:00Z")!,
              champions: ["Senna"],
              slug: "s1w3",
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-12T12:00:00Z")!,
              champions: ["Nocturne", "Senna"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-11T12:00:00Z")!,
              champions: ["Senna", "Fiora"],
              slug: "s1w1",
            ),
          ],
          dbChampions: [
            .init(
              id: uuid("1"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Nocturne",
              name: "Nocturne", title: "the Eternal Nightmare"),
            .init(
              id: uuid("2"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Senna",
              name: "Senna",
              title: "the Redeemer"),
            .init(
              id: uuid("3"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Fiora",
              name: "Fiora",
              title: "the Grand Duelist"),
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/champions/Nocturne",
          headers: reqHeaders(accessToken: accessToken),
          afterResponse: afterResponse,
        )
      }
    }

    @Test func championReleasedBetweenRotationMobile() async throws {
      try await championReleasedBetweenRotation(accessToken: mobileAccessToken) {
        res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "observing": false,
            "availability": [
              [
                "rotationType": "regular",
                "current": true,
                "lastAvailable": "2024-11-14T12:00:00Z",
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 1,
              "popularity": 3,
              "currentStreak": 1,
            ],
            "history": [
              [
                "type": "rotation",
                "id": "s1w4",
                "duration": [
                  "start": "2024-11-14T12:00:00Z",
                  "end": "2024-11-21T12:00:00Z",
                ],
                "current": true,
                "championImageUrls": [
                  imageUrl("Fiora"),
                  imageUrl("Nocturne"),
                ],
              ],
              [
                "type": "bench",
                "rotationsMissed": 1,
              ],
              [
                "type": "release",
                "releasedAt": "2024-11-13T00:00:00Z",
              ],
            ],
          ]
        )
      }
    }

    @Test func championReleasedBetweenRotationWeb() async throws {
      try await championReleasedBetweenRotation(accessToken: webApiKey) { res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "availability": [
              [
                "rotationType": "regular",
                "current": true,
                "lastAvailable": "2024-11-14T12:00:00Z",
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 1,
              "popularity": 3,
              "currentStreak": 1,
            ],
            "history": [
              [
                "type": "rotation",
                "id": "s1w4",
                "duration": [
                  "start": "2024-11-14T12:00:00Z",
                  "end": "2024-11-21T12:00:00Z",
                ],
                "current": true,
                "championImageUrls": [
                  imageUrl("Fiora"),
                  imageUrl("Nocturne"),
                ],
              ],
              [
                "type": "bench",
                "rotationsMissed": 1,
              ],
              [
                "type": "release",
                "releasedAt": "2024-11-13T00:00:00Z",
              ],
            ],
          ]
        )
      }
    }

    func championReleasedBetweenRotation(
      accessToken: String,
      afterResponse: (TestingHTTPResponse) async throws -> Void,
    ) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("4"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Fiora", "Nocturne"],
              slug: "s1w4",
            ),
            .init(
              id: uuid("3"),
              observedAt: .iso("2024-11-13T12:00:00Z")!,
              champions: ["Senna"],
              slug: "s1w3",
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-12T12:00:00Z")!,
              champions: ["Senna"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-11T12:00:00Z")!,
              champions: ["Senna", "Fiora"],
              slug: "s1w1",
            ),
          ],
          dbChampions: [
            .init(
              id: uuid("1"), releasedAt: .iso("2024-11-13T00:00:00Z")!, riotId: "Nocturne",
              name: "Nocturne", title: "the Eternal Nightmare"),
            .init(
              id: uuid("2"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Senna",
              name: "Senna",
              title: "the Redeemer"),
            .init(
              id: uuid("3"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Fiora",
              name: "Fiora",
              title: "the Grand Duelist"),
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/champions/Nocturne",
          headers: reqHeaders(accessToken: accessToken),
          afterResponse: afterResponse,
        )
      }
    }

    @Test func championReleasedBetweenRotationWithNegativeStreakMobile() async throws {
      try await championReleasedBetweenRotationWithNegativeStreak(accessToken: mobileAccessToken) {
        res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "observing": false,
            "availability": [
              [
                "rotationType": "regular",
                "current": false,
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 0,
              "popularity": 3,
              "currentStreak": -2,
            ],
            "history": [
              [
                "type": "bench",
                "rotationsMissed": 2,
              ],
              [
                "type": "release",
                "releasedAt": "2024-11-13T00:00:00Z",
              ],
            ],
          ]
        )
      }
    }

    @Test func championReleasedBetweenRotationWithNegativeStreakWeb() async throws {
      try await championReleasedBetweenRotationWithNegativeStreak(accessToken: webApiKey) {
        res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "availability": [
              [
                "rotationType": "regular",
                "current": false,
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 0,
              "popularity": 3,
              "currentStreak": -2,
            ],
            "history": [
              [
                "type": "bench",
                "rotationsMissed": 2,
              ],
              [
                "type": "release",
                "releasedAt": "2024-11-13T00:00:00Z",
              ],
            ],
          ]
        )
      }
    }

    func championReleasedBetweenRotationWithNegativeStreak(
      accessToken: String,
      afterResponse: (TestingHTTPResponse) async throws -> Void,
    ) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("4"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Fiora", "Senna"],
              slug: "s1w4",
            ),
            .init(
              id: uuid("3"),
              observedAt: .iso("2024-11-13T12:00:00Z")!,
              champions: ["Senna"],
              slug: "s1w3",
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-12T12:00:00Z")!,
              champions: ["Senna"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-11T12:00:00Z")!,
              champions: ["Senna", "Fiora"],
              slug: "s1w1",
            ),
          ],
          dbChampions: [
            .init(
              id: uuid("1"), releasedAt: .iso("2024-11-13T00:00:00Z")!, riotId: "Nocturne",
              name: "Nocturne", title: "the Eternal Nightmare"),
            .init(
              id: uuid("2"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Senna",
              name: "Senna",
              title: "the Redeemer"),
            .init(
              id: uuid("3"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Fiora",
              name: "Fiora",
              title: "the Grand Duelist"),
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/champions/Nocturne",
          headers: reqHeaders(accessToken: accessToken),
          afterResponse: afterResponse,
        )
      }
    }

    @Test func championWithHighRelativeScoreMobile() async throws {
      try await championWithHighRelativeScore(accessToken: mobileAccessToken) { res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "observing": false,
            "availability": [
              [
                "rotationType": "regular",
                "current": true,
                "lastAvailable": "2024-11-15T12:00:00Z",
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 2,
              "popularity": 2,
              "currentStreak": 2,
            ],
            "history": [
              [
                "type": "rotation",
                "id": "s1w5",
                "duration": [
                  "start": "2024-11-15T12:00:00Z",
                  "end": "2024-11-22T12:00:00Z",
                ],
                "current": true,
                "championImageUrls": [
                  imageUrl("Senna"),
                  imageUrl("Fiora"),
                  imageUrl("Nocturne"),
                ],
              ],
              [
                "type": "rotation",
                "id": "s1w4",
                "duration": [
                  "start": "2024-11-14T12:00:00Z",
                  "end": "2024-11-15T12:00:00Z",
                ],
                "current": false,
                "championImageUrls": [
                  imageUrl("Fiora"),
                  imageUrl("Nocturne"),
                ],
              ],
              [
                "type": "release",
                "releasedAt": "2024-11-14T00:00:00Z",
              ],
            ],
          ]
        )
      }
    }

    @Test func championWithHighRelativeScoreWeb() async throws {
      try await championWithHighRelativeScore(accessToken: webApiKey) { res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "availability": [
              [
                "rotationType": "regular",
                "current": true,
                "lastAvailable": "2024-11-15T12:00:00Z",
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 2,
              "popularity": 2,
              "currentStreak": 2,
            ],
            "history": [
              [
                "type": "rotation",
                "id": "s1w5",
                "duration": [
                  "start": "2024-11-15T12:00:00Z",
                  "end": "2024-11-22T12:00:00Z",
                ],
                "current": true,
                "championImageUrls": [
                  imageUrl("Senna"),
                  imageUrl("Fiora"),
                  imageUrl("Nocturne"),
                ],
              ],
              [
                "type": "rotation",
                "id": "s1w4",
                "duration": [
                  "start": "2024-11-14T12:00:00Z",
                  "end": "2024-11-15T12:00:00Z",
                ],
                "current": false,
                "championImageUrls": [
                  imageUrl("Fiora"),
                  imageUrl("Nocturne"),
                ],
              ],
              [
                "type": "release",
                "releasedAt": "2024-11-14T00:00:00Z",
              ],
            ],
          ]
        )
      }
    }

    func championWithHighRelativeScore(
      accessToken: String,
      afterResponse: (TestingHTTPResponse) async throws -> Void,
    ) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("5"),
              observedAt: .iso("2024-11-15T12:00:00Z")!,
              champions: ["Fiora", "Senna", "Nocturne"],
              slug: "s1w5",
            ),
            .init(
              id: uuid("4"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Fiora", "Nocturne"],
              slug: "s1w4",
            ),
            .init(
              id: uuid("3"),
              observedAt: .iso("2024-11-13T12:00:00Z")!,
              champions: ["Senna"],
              slug: "s1w3",
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-12T12:00:00Z")!,
              champions: ["Senna", "Fiora"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-11T12:00:00Z")!,
              champions: ["Fiora"],
              slug: "s1w1",
            ),
          ],
          dbChampions: [
            .init(
              id: uuid("1"), releasedAt: .iso("2024-11-14T00:00:00Z")!, riotId: "Nocturne",
              name: "Nocturne", title: "the Eternal Nightmare"),
            .init(
              id: uuid("2"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Senna",
              name: "Senna",
              title: "the Redeemer"),
            .init(
              id: uuid("3"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Fiora",
              name: "Fiora",
              title: "the Grand Duelist"),
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 5)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/champions/Nocturne",
          headers: reqHeaders(accessToken: accessToken),
          afterResponse: afterResponse,
        )
      }
    }

    @Test func userObservingChampion() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbChampions: [
            .init(
              id: uuid("1"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Nocturne",
              name: "Nocturne", title: "the Eternal Nightmare")
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbUserWatchlists: [
            .init(userId: mobileUserId, champions: [uuidString("1")])
          ],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/champions/Nocturne",
          headers: reqHeaders(accessToken: mobileAccessToken)
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "id": "nocturne",
              "imageUrl": imageUrl("Nocturne"),
              "name": "Nocturne",
              "title": "the Eternal Nightmare",
              "observing": true,
              "availability": [
                [
                  "rotationType": "regular",
                  "current": false,
                ],
                [
                  "rotationType": "beginner",
                  "current": false,
                ],
              ],
              "overview": [
                "occurrences": 0,
                "popularity": 1,
                "currentStreak": 0,
              ],
              "history": [
                [
                  "type": "release",
                  "releasedAt": "2024-01-01T00:00:00Z",
                ]
              ],
            ]
          )
        }
      }
    }

    @Test func userNotObservingChampion() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbChampions: [
            .init(
              id: uuid("1"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Nocturne",
              name: "Nocturne", title: "the Eternal Nightmare")
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbUserWatchlists: [
            .init(userId: mobileUserId, champions: [uuidString("2")])
          ],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/champions/Nocturne",
          headers: reqHeaders(accessToken: mobileAccessToken)
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "id": "nocturne",
              "imageUrl": imageUrl("Nocturne"),
              "name": "Nocturne",
              "title": "the Eternal Nightmare",
              "observing": false,
              "availability": [
                [
                  "rotationType": "regular",
                  "current": false,
                ],
                [
                  "rotationType": "beginner",
                  "current": false,
                ],
              ],
              "overview": [
                "occurrences": 0,
                "popularity": 1,
                "currentStreak": 0,
              ],
              "history": [
                [
                  "type": "release",
                  "releasedAt": "2024-01-01T00:00:00Z",
                ]
              ],
            ]
          )
        }
      }
    }

    @Test func inactiveRotationMobile() async throws {
      try await inactiveRotation(accessToken: mobileAccessToken) { res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "observing": false,
            "availability": [
              [
                "rotationType": "regular",
                "current": true,
                "lastAvailable": "2024-11-14T12:00:00Z",
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 2,
              "popularity": 2,
              "currentStreak": 1,
            ],
            "history": [
              [
                "type": "rotation",
                "id": "s1w4",
                "duration": [
                  "start": "2024-11-14T12:00:00Z",
                  "end": "2024-11-21T12:00:00Z",
                ],
                "current": true,
                "championImageUrls": [
                  imageUrl("Senna"),
                  imageUrl("Nocturne"),
                ],
              ],
              [
                "type": "bench",
                "rotationsMissed": 1,
              ],
              [
                "type": "rotation",
                "id": "s1w1",
                "duration": [
                  "start": "2024-11-11T12:00:00Z",
                  "end": "2024-11-12T12:00:00Z",
                ],
                "current": false,
                "championImageUrls": [
                  imageUrl("Nocturne"),
                  imageUrl("Fiora"),
                  imageUrl("Senna"),
                ],
              ],
              [
                "type": "release",
                "releasedAt": "2024-01-01T00:00:00Z",
              ],
            ],
          ]
        )
      }
    }

    @Test func inactiveRotationWeb() async throws {
      try await inactiveRotation(accessToken: webApiKey) { res async throws in
        #expect(res.status == .ok)
        try expectBody(
          res.body,
          [
            "id": "nocturne",
            "imageUrl": imageUrl("Nocturne"),
            "name": "Nocturne",
            "title": "the Eternal Nightmare",
            "availability": [
              [
                "rotationType": "regular",
                "current": true,
                "lastAvailable": "2024-11-14T12:00:00Z",
              ],
              [
                "rotationType": "beginner",
                "current": false,
              ],
            ],
            "overview": [
              "occurrences": 2,
              "popularity": 2,
              "currentStreak": 1,
            ],
            "history": [
              [
                "type": "rotation",
                "id": "s1w4",
                "duration": [
                  "start": "2024-11-14T12:00:00Z",
                  "end": "2024-11-21T12:00:00Z",
                ],
                "current": true,
                "championImageUrls": [
                  imageUrl("Senna"),
                  imageUrl("Nocturne"),
                ],
              ],
              [
                "type": "bench",
                "rotationsMissed": 1,
              ],
              [
                "type": "rotation",
                "id": "s1w1",
                "duration": [
                  "start": "2024-11-11T12:00:00Z",
                  "end": "2024-11-12T12:00:00Z",
                ],
                "current": false,
                "championImageUrls": [
                  imageUrl("Nocturne"),
                  imageUrl("Fiora"),
                  imageUrl("Senna"),
                ],
              ],
              [
                "type": "release",
                "releasedAt": "2024-01-01T00:00:00Z",
              ],
            ],
          ]
        )
      }
    }

    func inactiveRotation(
      accessToken: String,
      afterResponse: (TestingHTTPResponse) async throws -> Void,
    ) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("4"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Nocturne", "Senna"],
              slug: "s1w4",
            ),
            .init(
              id: uuid("3"),
              active: false,
              observedAt: .iso("2024-11-13T12:00:00Z")!,
              champions: ["Nocturne", "Senna", "Fiora"],
              slug: "s1w3",
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-12T12:00:00Z")!,
              champions: ["Senna"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-11T12:00:00Z")!,
              champions: ["Nocturne", "Senna", "Fiora"],
              slug: "s1w1",
            ),
          ],
          dbChampions: [
            .init(
              id: uuid("1"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Nocturne",
              name: "Nocturne", title: "the Eternal Nightmare"),
            .init(
              id: uuid("2"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Senna",
              name: "Senna",
              title: "the Redeemer"),
            .init(
              id: uuid("3"), releasedAt: .iso("2024-01-01T00:00:00Z")!, riotId: "Fiora",
              name: "Fiora",
              title: "the Grand Duelist"),
          ],
          dbPatchVersions: [.init(value: "15.0.1")],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/champions/Nocturne",
          headers: reqHeaders(accessToken: accessToken),
          afterResponse: afterResponse,
        )
      }
    }
  }
}
