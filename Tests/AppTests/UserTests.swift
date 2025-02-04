import XCTVapor

@testable import App

class UserTests: AppTests {
  func testInvalidAuth() async throws {
    _ = try await testConfigureWith()

    try await app.test(
      .GET, "/user"
    ) { res async in
      XCTAssertEqual(res.status, .unauthorized)
      XCTAssertBodyError(res.body, "Invalid device id")
    }
  }

  func testValidAuth() async throws {
    _ = try await testConfigureWith()

    try await app.test(
      .GET, "/user",
      headers: ["X-Device-Id": "123"]
    ) { res async in
      XCTAssertEqual(res.status, .ok)
    }
  }

  func testAddingNotificationsConfig() async throws {
    _ = try await testConfigureWith(
      dbNotificationsConfigs: [
        .init(deviceId: "456", token: "abc", enabled: true)
      ]
    )

    try await app.test(
      .GET, "/user",
      headers: ["X-Device-Id": "123"]
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(res.body, ["notificationsTokenSynced": false])
    }
  }

  func testUpdatingNotificationsConfig() async throws {
    _ = try await testConfigureWith(
      dbNotificationsConfigs: [
        .init(deviceId: "123", token: "abc", enabled: true)
      ]
    )

    try await app.test(
      .GET, "/user",
      headers: ["X-Device-Id": "123"]
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(res.body, ["notificationsTokenSynced": true])
    }
  }
}
