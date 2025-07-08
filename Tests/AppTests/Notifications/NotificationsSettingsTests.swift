import Testing

@testable import App

extension AppTests {
  @Suite(.serialized) struct GetNotificationsSettingsTests {
    @Test func invalidAuth() async throws {
      try await withApp { app in

        _ = try await app.testConfigureWith()

        try await app.test(
          .GET, "/notifications/settings",
          headers: reqHeaders()
        ) { res async throws in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test func validAuth() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .GET, "/notifications/settings",
          headers: reqHeaders(accessToken: mobileToken)
        ) { res async throws in
          #expect(res.status == .notFound)
        }
      }
    }

    @Test func nonExistingConfig() async throws {
      try await withApp { app in
        let existingConfig = NotificationsConfigModel(
          userId: "123", token: "def",
          rotationChanged: true, championsAvailable: true
        )

        _ = try await app.testConfigureWith(dbNotificationsConfigs: [existingConfig])

        try await app.test(
          .GET, "/notifications/settings",
          headers: reqHeaders(accessToken: mobileToken)
        ) { res async throws in
          #expect(res.status == .notFound)
        }
      }
    }

    @Test func existingConfig() async throws {
      try await withApp { app in
        let existingConfig = NotificationsConfigModel(
          userId: mobileUserId, token: "abc",
          rotationChanged: true, championsAvailable: true
        )

        _ = try await app.testConfigureWith(dbNotificationsConfigs: [existingConfig])

        try await app.test(
          .GET, "/notifications/settings",
          headers: reqHeaders(accessToken: mobileToken)
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            ["rotationChanged": true, "championsAvailable": true]
          )
        }
      }
    }
  }

  @Suite(.serialized) struct PutNotificationsSettingsTests {
    @Test func invalidAuth() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .PUT, "/notifications/settings",
          headers: reqHeaders(),
          body: ["rotationChanged": true, "championsAvailable": true]
        ) { res async throws in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test func validAuth() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .PUT, "/notifications/settings",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["rotationChanged": true, "championsAvailable": true]
        ) { res async throws in
          #expect(res.status == .noContent)
        }
      }
    }

    @Test func addingSettings() async throws {
      try await withApp { app in
        let existingConfig = NotificationsConfigModel(
          userId: "123", token: "def",
          rotationChanged: false, championsAvailable: false
        )

        _ = try await app.testConfigureWith(dbNotificationsConfigs: [existingConfig])

        try await app.test(
          .PUT, "/notifications/settings",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["rotationChanged": true, "championsAvailable": true]
        ) { res async throws in
          let addedConfig = NotificationsConfigModel(
            userId: mobileUserId, token: "",
            rotationChanged: true, championsAvailable: true
          )
          let configs = try await app.dbNotificationConfigs()

          #expect(res.status == .noContent)
          #expect(configs == [existingConfig, addedConfig])
        }
      }
    }

    @Test func updatingSettings() async throws {
      try await withApp { app in
        let existingConfig = NotificationsConfigModel(
          userId: mobileUserId, token: "abc",
          rotationChanged: false, championsAvailable: true
        )

        _ = try await app.testConfigureWith(dbNotificationsConfigs: [existingConfig])

        try await app.test(
          .PUT, "/notifications/settings",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["rotationChanged": true, "championsAvailable": false]
        ) { res async throws in
          let updatedConfig = NotificationsConfigModel(
            userId: mobileUserId, token: "abc",
            rotationChanged: true, championsAvailable: false
          )
          let configs = try await app.dbNotificationConfigs()

          #expect(res.status == .noContent)
          #expect(configs == [updatedConfig])
        }
      }
    }
  }
}
