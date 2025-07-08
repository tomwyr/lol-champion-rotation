import Testing

@testable import App

extension AppTests {
  @Suite(.serialized) struct PutNotificationsTokenTests {
    @Test func invalidAuth() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .PUT, "/notifications/token",
          headers: reqHeaders(),
          body: ["token": "123"]
        ) { res async throws in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test func validAuth() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .PUT, "/notifications/token",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["token": "abc"]
        ) { res async throws in
          #expect(res.status == .noContent)
        }
      }
    }

    @Test func addingNewToken() async throws {
      try await withApp { app in
        let existingConfig = NotificationsConfigModel(
          userId: "123", token: "def",
          rotationChanged: true, championsAvailable: true
        )

        _ = try await app.testConfigureWith(dbNotificationsConfigs: [existingConfig])

        try await app.test(
          .PUT, "/notifications/token",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["token": "abc"]
        ) { res async throws in
          let addedConfig = NotificationsConfigModel(
            userId: mobileUserId, token: "abc",
            rotationChanged: false, championsAvailable: false
          )
          let configs = try await app.dbNotificationConfigs()

          #expect(res.status == .noContent)
          #expect(configs == [existingConfig, addedConfig])
        }
      }
    }

    @Test func updatingExistingToken() async throws {
      try await withApp { app in
        let existingConfig = NotificationsConfigModel(
          userId: mobileUserId, token: "def",
          rotationChanged: true, championsAvailable: true
        )

        _ = try await app.testConfigureWith(dbNotificationsConfigs: [existingConfig])

        try await app.test(
          .PUT, "/notifications/token",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["token": "abc"]
        ) { res async throws in
          let updatedConfig = NotificationsConfigModel(
            userId: mobileUserId, token: "abc",
            rotationChanged: true, championsAvailable: true
          )
          let configs = try await app.dbNotificationConfigs()

          #expect(res.status == .noContent)
          #expect(configs == [updatedConfig])
        }
      }
    }
  }
}
