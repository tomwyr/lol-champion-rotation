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
        .init(userId: "123", token: "abc", currentRotation: true, observedChampions: true)
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
          currentRotation: false, observedChampions: false
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
      (currentRotation: true, observedChampions: false),
      (currentRotation: false, observedChampions: true),
      (currentRotation: true, observedChampions: true),
    ]

    for (currentRotation, observedChampions) in configs {
      _ = try await testConfigureWith(
        dbNotificationsConfigs: [
          .init(
            userId: mobileUserId, token: "abc",
            currentRotation: currentRotation, observedChampions: observedChampions
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
