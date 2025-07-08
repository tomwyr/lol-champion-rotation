import Testing

@testable import App

extension AppTests {
  @Suite(.serialized) struct ObservedRotationsTests {
    @Test func unauthorizedUser() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbRegularRotations: [
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-21T12:00:00Z")!,
              champions: ["Nocturne"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Nocturne"],
              slug: "s1w1",
            ),
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne")
          ],
          b2AuthorizeDownloadData: .init(authorizationToken: "123"),
        )

        try await app.test(
          .GET, "/rotations/observed"
        ) { res async throws in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test func authorizedUser() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbRegularRotations: [
            .init(
              id: uuid("3"),
              observedAt: .iso("2024-11-21T12:00:00Z")!,
              champions: ["Garen"],
              slug: "s1w3",
            ),
            .init(
              id: uuid("2"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Nocturne"],
              slug: "s1w2",
            ),
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-07T12:00:00Z")!,
              champions: ["Nocturne"],
              slug: "s1w1",
            ),
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),

          ],
          dbUserWatchlists: [
            .init(
              userId: mobileUserId,
              rotations: [uuidString("1"), uuidString("3")]
            )
          ],
          b2AuthorizeDownloadData: .init(authorizationToken: "123"),
        )

        try await app.test(
          .GET, "/rotations/observed",
          headers: reqHeaders(accessToken: mobileToken)
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "rotations": [
                [
                  "id": "s1w3",
                  "current": true,
                  "duration": [
                    "start": "2024-11-21T12:00:00Z",
                    "end": "2024-11-28T12:00:00Z",
                  ],
                  "championImageUrls": [
                    imageUrl("Garen")
                  ],
                ],
                [
                  "id": "s1w1",
                  "current": false,
                  "duration": [
                    "start": "2024-11-07T12:00:00Z",
                    "end": "2024-11-14T12:00:00Z",
                  ],
                  "championImageUrls": [
                    imageUrl("Nocturne")
                  ],
                ],
              ]
            ]
          )
        }
      }
    }

    @Test func userWithoutWatchlist() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-07T12:00:00Z")!,
              champions: ["Nocturne"],
              slug: "s1w1"
            )
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne")

          ],
          dbUserWatchlists: [],
          b2AuthorizeDownloadData: .init(authorizationToken: "123"),
        )

        try await app.test(
          .GET, "/rotations/observed",
          headers: reqHeaders(accessToken: mobileToken)
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "rotations": []
            ]
          )
        }
      }
    }
  }
}
