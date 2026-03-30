import Testing

@testable import App

extension AppTests {
  @Suite(.serialized) struct UserTests {
    @Test func invalidAuth() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .GET, "/user"
        ) { res async throws in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test func validAuth() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .GET, "/user",
          headers: reqHeaders(accessToken: mobileAccessToken),
        ) { res async throws in
          #expect(res.status == .ok)
        }
      }
    }

    @Test func uninitializedNotifications() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbNotificationsConfigs: [
            .enabled(userId: "123", token: "")
          ]
        )

        try await app.test(
          .GET, "/user",
          headers: reqHeaders(accessToken: mobileAccessToken),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            ["notificationsEnabled": false],
          )
        }
      }
    }

    @Test func disabledNotifications() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbNotificationsConfigs: [
            .disabled(userId: mobileUserId, token: "abc")
          ]
        )

        try await app.test(
          .GET, "/user",
          headers: reqHeaders(accessToken: mobileAccessToken),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            ["notificationsToken": "abc", "notificationsEnabled": false],
          )
        }
      }
    }

    @Test func enabledNotifications() async throws {
      let configs = [
        (rotationChanged: true, championsAvailable: true, championReleased: true),

        (rotationChanged: true, championsAvailable: false, championReleased: false),
        (rotationChanged: true, championsAvailable: true, championReleased: false),
        (rotationChanged: true, championsAvailable: false, championReleased: true),

        (rotationChanged: false, championsAvailable: true, championReleased: false),
        (rotationChanged: true, championsAvailable: true, championReleased: true),
        (rotationChanged: true, championsAvailable: true, championReleased: false),

        (rotationChanged: false, championsAvailable: false, championReleased: true),
        (rotationChanged: true, championsAvailable: true, championReleased: true),
        (rotationChanged: false, championsAvailable: true, championReleased: true),
      ]

      for (rotationChanged, championsAvailable, championReleased) in configs {
        try await withApp { app in
          _ = try await app.testConfigureWith(
            dbNotificationsConfigs: [
              .init(
                userId: mobileUserId, token: "abc",
                rotationChanged: rotationChanged,
                championsAvailable: championsAvailable,
                championReleased: championReleased,
              )
            ]
          )

          try await app.test(
            .GET, "/user",
            headers: reqHeaders(accessToken: mobileAccessToken),
          ) { res async throws in
            #expect(res.status == .ok)
            try expectBody(
              res.body,
              ["notificationsToken": "abc", "notificationsEnabled": true],
            )
          }
        }
      }
    }
  }
}
