import Testing

@testable import App

extension AppTests {
  @Suite(.serialized) struct UpdateObserveRotationTests {
    @Test func unauthorizedUser() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbRegularRotations: [
            .init(id: uuid("1"), slug: "s1w1")
          ],
        )

        try await app.test(
          .POST, "/rotations/s1w1/observe",
          body: ["observing": true]
        ) { res async throws in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test func addingNonObservedRotation() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbRegularRotations: [
            .init(id: uuid("1"), slug: "s1w1")
          ],
          dbUserWatchlists: [
            .init(userId: mobileUserId, rotations: [uuidString("2")])
          ],
        )

        try await app.test(
          .POST, "/rotations/s1w1/observe",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["observing": true]
        ) { res async throws in
          let watchlists = try await app.dbUserWatchlists(userId: mobileUserId)
          #expect(res.status == .ok)
          #expect(watchlists?.rotations == [uuidString("2"), uuidString("1")])
        }
      }
    }

    @Test func addingObservedRotation() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbRegularRotations: [
            .init(id: uuid("1"), slug: "s1w1")
          ],
          dbUserWatchlists: [
            .init(userId: mobileUserId, rotations: [uuidString("1")])
          ]
        )

        try await app.test(
          .POST, "/rotations/s1w1/observe",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["observing": true]
        ) { res async throws in
          let watchlists = try await app.dbUserWatchlists(userId: mobileUserId)
          #expect(res.status == .ok)
          #expect(watchlists?.rotations == [uuidString("1")])
        }
      }
    }

    @Test func removingObservedRotation() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbRegularRotations: [
            .init(id: uuid("1"), slug: "s1w1")
          ],
          dbUserWatchlists: [
            .init(userId: mobileUserId, rotations: [uuidString("1")])
          ]
        )

        try await app.test(
          .POST, "/rotations/s1w1/observe",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["observing": false]
        ) { res async throws in
          let watchlists = try await app.dbUserWatchlists(userId: mobileUserId)
          #expect(res.status == .ok)
          #expect(watchlists?.rotations == [])
        }
      }
    }

    @Test func removingNonObservedRotation() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbRegularRotations: [
            .init(id: uuid("1"), slug: "s1w1")
          ],
          dbUserWatchlists: [
            .init(userId: mobileUserId, rotations: [uuidString("2")])
          ]
        )

        try await app.test(
          .POST, "/rotations/s1w1/observe",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["observing": false]
        ) { res async throws in
          let watchlists = try await app.dbUserWatchlists(userId: mobileUserId)
          #expect(res.status == .ok)
          #expect(watchlists?.rotations == [uuidString("2")])
        }
      }
    }

    @Test func addingWithoutWatchlist() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbRegularRotations: [
            .init(id: uuid("1"), slug: "s1w1")
          ],
          dbUserWatchlists: []
        )

        try await app.test(
          .POST, "/rotations/s1w1/observe",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["observing": true]
        ) { res async throws in
          let watchlists = try await app.dbUserWatchlists(userId: mobileUserId)
          #expect(res.status == .ok)
          #expect(watchlists?.rotations == [uuidString("1")])
        }
      }
    }

    @Test func unknownRotation() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbRegularRotations: [
            .init(id: uuid("1"), slug: "s1w1")
          ],
          dbUserWatchlists: [
            .init(userId: mobileUserId, rotations: [uuidString("1")])
          ]
        )

        try await app.test(
          .POST, "/rotations/s1w2/observe",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["observing": true]
        ) { res async throws in
          #expect(res.status == .notFound)
        }
      }
    }

    @Test func inactiveRotation() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbRegularRotations: [
            .init(id: uuid("1"), active: false, slug: "s1w1")
          ],
          dbUserWatchlists: [
            .init(userId: mobileUserId, rotations: [uuidString("1")])
          ]
        )

        try await app.test(
          .POST, "/rotations/s1w1/observe",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["observing": true]
        ) { res async throws in
          #expect(res.status == .notFound)
        }
      }
    }
  }
}
