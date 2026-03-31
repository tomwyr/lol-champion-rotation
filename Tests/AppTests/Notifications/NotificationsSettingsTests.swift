import Testing

@testable import App

extension AppTests {
  @Suite(.serialized) struct GetNotificationsSettingsTests {
    @Test func missingAuth() async throws {
      try await withApp { app in

        _ = try await app.testConfigureWith()

        try await app.test(
          .GET, "/notifications/settings",
          headers: reqHeaders(),
        ) { res async throws in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test func webAuth() async throws {
      try await withApp { app in

        _ = try await app.testConfigureWith()

        try await app.test(
          .GET, "/notifications/settings",
          headers: reqHeaders(accessToken: webApiKey),
        ) { res async throws in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test func mobileAuth() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .GET, "/notifications/settings",
          headers: reqHeaders(accessToken: mobileAccessToken),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            ["rotationChanged": false, "championsAvailable": false, "championReleased": false],
          )
        }
      }
    }

    @Test func nonExistingConfig() async throws {
      try await withApp { app in
        let existingConfig = NotificationsConfigModel.enabled(
          userId: "123", token: "def",
        )

        _ = try await app.testConfigureWith(dbNotificationsConfigs: [existingConfig])

        try await app.test(
          .GET, "/notifications/settings",
          headers: reqHeaders(accessToken: mobileAccessToken),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            ["rotationChanged": false, "championsAvailable": false, "championReleased": false]
          )
        }
      }
    }

    @Test func existingConfig() async throws {
      try await withApp { app in
        let existingConfig = NotificationsConfigModel.enabled(
          userId: mobileUserId, token: "abc",
        )

        _ = try await app.testConfigureWith(dbNotificationsConfigs: [existingConfig])

        try await app.test(
          .GET, "/notifications/settings",
          headers: reqHeaders(accessToken: mobileAccessToken),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            ["rotationChanged": true, "championsAvailable": true, "championReleased": true]
          )
        }
      }
    }
  }

  @Suite(.serialized) struct PutNotificationsSettingsTests {
    @Test func missingAuth() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .PUT, "/notifications/settings",
          headers: reqHeaders(),
          body: ["rotationChanged": true, "championsAvailable": true, "championReleased": true],
        ) { res async throws in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test func webAuth() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .PUT, "/notifications/settings",
          headers: reqHeaders(accessToken: webApiKey),
          body: ["rotationChanged": true, "championsAvailable": true, "championReleased": true],
        ) { res async throws in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test func mobileAuth() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .PUT, "/notifications/settings",
          headers: reqHeaders(accessToken: mobileAccessToken),
          body: ["rotationChanged": true, "championsAvailable": true, "championReleased": true],
        ) { res async throws in
          #expect(res.status == .noContent)
        }
      }
    }

    @Test func addingSettings() async throws {
      try await withApp { app in
        let existingConfig = NotificationsConfigModel.disabled(
          userId: "123", token: "def",
        )

        _ = try await app.testConfigureWith(dbNotificationsConfigs: [existingConfig])

        try await app.test(
          .PUT, "/notifications/settings",
          headers: reqHeaders(accessToken: mobileAccessToken),
          body: ["rotationChanged": true, "championsAvailable": true, "championReleased": true],
        ) { res async throws in
          let addedConfig = NotificationsConfigModel.enabled(
            userId: mobileUserId, token: "",
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
          rotationChanged: false, championsAvailable: false, championReleased: false,
        )

        _ = try await app.testConfigureWith(dbNotificationsConfigs: [existingConfig])

        try await app.test(
          .PUT, "/notifications/settings",
          headers: reqHeaders(accessToken: mobileAccessToken),
          body: ["rotationChanged": true, "championsAvailable": true, "championReleased": true],
        ) { res async throws in
          let updatedConfig = NotificationsConfigModel(
            userId: mobileUserId, token: "abc",
            rotationChanged: true, championsAvailable: true, championReleased: true,
          )
          let configs = try await app.dbNotificationConfigs()

          #expect(res.status == .noContent)
          #expect(configs == [updatedConfig])
        }
      }
    }
  }
}
