import XCTVapor

@testable import App

class UserTests: AppTests {
  func testInvalidAuth() async throws {
    _ = try await testConfigureWith()

    try await app.test(
      .GET, "/user"
    ) { res async in
      XCTAssertEqual(res.status, .unauthorized)
    }
  }

  func testValidAuth() async throws {
    _ = try await testConfigureWith()

    try await app.test(
      .GET, "/user",
      headers: ["Authorization": "Bearer \(mobileToken)"]
    ) { res async in
      XCTAssertEqual(res.status, .ok)
    }
  }

  func testUninitializedNotifications() async throws {
    _ = try await testConfigureWith(
      dbNotificationsConfigs: [
        .init(userId: "123", token: "abc", rotationChanged: true, championsAvailable: true)
      ]
    )

    try await app.test(
      .GET, "/user",
      headers: ["Authorization": "Bearer \(mobileToken)"]
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(res.body, ["notificationsStatus": "uninitialized"])
    }
  }

  func testDisabledNotifications() async throws {
    _ = try await testConfigureWith(
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
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(res.body, ["notificationsStatus": "disabled"])
    }
  }

  func testEnabledNotifications() async throws {
    let configs = [
      (rotationChanged: true, championsAvailable: false),
      (rotationChanged: false, championsAvailable: true),
      (rotationChanged: true, championsAvailable: true),
    ]

    for (rotationChanged, championsAvailable) in configs {
      _ = try await testConfigureWith(
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
      ) { res async in
        XCTAssertEqual(res.status, .ok)
        XCTAssertBody(res.body, ["notificationsStatus": "enabled"])
      }
    }
  }
}
