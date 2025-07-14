import Testing

@testable import App

extension AppTests {
  @Suite(.serialized) struct UpdateObservChampionTests {
    @Test func unauthorizedUser() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .POST, "/champions/Nocturne/observe",
          body: ["observing": true]
        ) { res async throws in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test func addingNonObservedChampion() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen"),
          ],
          dbUserWatchlists: [
            .init(userId: mobileUserId, champions: [uuidString("2")])
          ],
        )

        try await app.test(
          .POST, "/champions/Nocturne/observe",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["observing": true]
        ) { res async throws in
          let watchlists = try await app.dbUserWatchlists(userId: mobileUserId)
          #expect(res.status == .ok)
          #expect(watchlists?.champions == [uuidString("2"), uuidString("1")])
        }
      }
    }

    @Test func addingObservedChampion() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne")
          ],
          dbUserWatchlists: [
            .init(userId: mobileUserId, champions: [uuidString("1")])
          ]
        )

        try await app.test(
          .POST, "/champions/Nocturne/observe",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["observing": true]
        ) { res async throws in
          let watchlists = try await app.dbUserWatchlists(userId: mobileUserId)
          #expect(res.status == .ok)
          #expect(watchlists?.champions == [uuidString("1")])
        }
      }
    }

    @Test func removingObservedChampion() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne")
          ],
          dbUserWatchlists: [
            .init(userId: mobileUserId, champions: [uuidString("1")])
          ]
        )

        try await app.test(
          .POST, "/champions/Nocturne/observe",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["observing": false]
        ) { res async throws in
          let watchlists = try await app.dbUserWatchlists(userId: mobileUserId)
          #expect(res.status == .ok)
          #expect(watchlists?.champions == [])
        }
      }
    }

    @Test func removingNonObservedChampion() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne"),
            .init(id: uuid("2"), riotId: "Garen"),
          ],
          dbUserWatchlists: [
            .init(userId: mobileUserId, champions: [uuidString("2")])
          ]
        )

        try await app.test(
          .POST, "/champions/Nocturne/observe",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["observing": false]
        ) { res async throws in
          let watchlists = try await app.dbUserWatchlists(userId: mobileUserId)
          #expect(res.status == .ok)
          #expect(watchlists?.champions == [uuidString("2")])
        }
      }
    }

    @Test func addingWithoutWatchlist() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne")
          ],
          dbUserWatchlists: [],
        )

        try await app.test(
          .POST, "/champions/Nocturne/observe",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["observing": true]
        ) { res async throws in
          let watchlists = try await app.dbUserWatchlists(userId: mobileUserId)
          #expect(res.status == .ok)
          #expect(watchlists?.champions == [uuidString("1")])
        }
      }
    }

    @Test func addingChampionCaseInsensitive() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne")
          ],
          dbUserWatchlists: [
            .init(userId: mobileUserId, champions: [uuidString("1")])
          ]
        )

        try await app.test(
          .POST, "/champions/nocturne/observe",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["observing": true]
        ) { res async throws in
          let watchlists = try await app.dbUserWatchlists(userId: mobileUserId)
          #expect(res.status == .ok)
          #expect(watchlists?.champions == [uuidString("1")])
        }
      }
    }

    @Test func removingChampionCaseInsensitive() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbChampions: [
            .init(id: uuid("1"), riotId: "Nocturne")
          ],
          dbUserWatchlists: [
            .init(userId: mobileUserId, champions: [uuidString("1")])
          ]
        )

        try await app.test(
          .POST, "/champions/nocturne/observe",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["observing": false]
        ) { res async throws in
          let watchlists = try await app.dbUserWatchlists(userId: mobileUserId)
          #expect(res.status == .ok)
          #expect(watchlists?.champions == [])
        }
      }
    }

    @Test func unknownChampion() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbChampions: [
            .init(id: uuid("1"), riotId: "Garen"),
          ],
          dbUserWatchlists: [
            .init(userId: mobileUserId, champions: [uuidString("1")])
          ],
        )

        try await app.test(
          .POST, "/champions/Nocturne/observe",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["observing": true]
        ) { res async throws in
          #expect(res.status == .notFound)
        }
      }
    }
  }
}
