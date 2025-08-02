import Testing

@testable import App

extension AppTests {
  @Suite(.serialized) struct ObservedChampionsTests {
    @Test func unauthorizedUser() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: ["Nocturne"],
              slug: "s1w1",
            )
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne")
          ],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/champions/observed"
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
              id: uuid("1"),
              observedAt: .iso("2024-11-07T12:00:00Z")!,
              champions: ["Nunu"],
              slug: "s1w1",
            )
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Senna", name: "Senna"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Nunu", name: "Nunu & Willump"),
          ],
          dbUserWatchlists: [
            .init(
              userId: mobileUserId,
              champions: [uuidString("1"), uuidString("3")]
            )
          ],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/champions/observed",
          headers: reqHeaders(accessToken: mobileToken)
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "champions": [
                [
                  "id": "Nunu",
                  "name": "Nunu & Willump",
                  "current": true,
                  "imageUrl": imageUrl("Nunu"),
                ],
                [
                  "id": "Senna",
                  "name": "Senna",
                  "current": false,
                  "imageUrl": imageUrl("Senna"),
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
              slug: "s1w1",
            )
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne", name: "Nocturne")

          ],
          dbUserWatchlists: [],
          b2AuthorizeDownloadData: .init(authorizationToken: "123")
        )

        try await app.test(
          .GET, "/champions/observed",
          headers: reqHeaders(accessToken: mobileToken)
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "champions": []
            ]
          )
        }
      }
    }
  }
}
