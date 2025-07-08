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
          headers: ["Authorization": "Bearer \(mobileToken)"]
        ) { res async throws in
          #expect(res.status == .ok)
        }
      }
    }

    @Test func uninitializedNotifications() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbNotificationsConfigs: [
            .init(userId: "123", token: "abc", rotationChanged: true, championsAvailable: true)
          ]
        )

        try await app.test(
          .GET, "/user",
          headers: ["Authorization": "Bearer \(mobileToken)"]
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(res.body, ["notificationsStatus": "uninitialized"])
        }
      }
    }

    @Test func disabledNotifications() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          dbNotificationsConfigs: [
            .init(
              userId: mobileUserId, token: "abc",
              rotationChanged: false, championsAvailable: false
            )
          ]
        )

        try await app.test(
          .GET, "/user",
          headers: ["Authorization": "Bearer \(mobileToken)"]
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(res.body, ["notificationsStatus": "disabled"])
        }
      }
    }

    @Test func enabledNotifications() async throws {
      let configs = [
        (rotationChanged: true, championsAvailable: false),
        (rotationChanged: false, championsAvailable: true),
        (rotationChanged: true, championsAvailable: true),
      ]

      for (rotationChanged, championsAvailable) in configs {
        try await withApp { app in
          _ = try await app.testConfigureWith(
            dbNotificationsConfigs: [
              .init(
                userId: mobileUserId, token: "abc",
                rotationChanged: rotationChanged, championsAvailable: championsAvailable
              )
            ]
          )

          try await app.test(
            .GET, "/user",
            headers: ["Authorization": "Bearer \(mobileToken)"]
          ) { res async throws in
            #expect(res.status == .ok)
            try expectBody(res.body, ["notificationsStatus": "enabled"])
          }
        }
      }
    }
  }
}
