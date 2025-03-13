import XCTVapor

@testable import App

class PutNotificationsTokenTests: AppTests {
  func testInvalidAuth() async throws {
    _ = try await testConfigureWith()

    try await app.test(
      .PUT, "/notifications/token",
      headers: reqHeaders(),
      body: ["token": "abc"]
    ) { res async in
      XCTAssertEqual(res.status, .unauthorized)
      XCTAssertBodyError(res.body, "Invalid device id")
    }
  }

  func testValidAuth() async throws {
    _ = try await testConfigureWith()

    try await app.test(
      .PUT, "/notifications/token",
      headers: reqHeaders(accessToken: "123"),
      body: ["token": "abc"]
    ) { res async in
      XCTAssertEqual(res.status, .noContent)
    }
  }

  func testAddingNewToken() async throws {
    let existingConfig = NotificationsConfigModel(userId: "456", token: "def", enabled: true)

    _ = try await testConfigureWith(dbNotificationsConfigs: [existingConfig])

    try await app.test(
      .PUT, "/notifications/token",
      headers: reqHeaders(accessToken: "123"),
      body: ["token": "abc"]
    ) { res async throws in
      let addedConfig = NotificationsConfigModel(userId: "123", token: "abc", enabled: false)
      let configs = try await dbNotificationConfigs()

      XCTAssertEqual(res.status, .noContent)
      XCTAssertEqual(configs, [existingConfig, addedConfig])
    }
  }

  func testUpdatingExistingToken() async throws {
    let existingConfig = NotificationsConfigModel(userId: "123", token: "def", enabled: true)

    _ = try await testConfigureWith(dbNotificationsConfigs: [existingConfig])

    try await app.test(
      .PUT, "/notifications/token",
      headers: reqHeaders(accessToken: "123"),
      body: ["token": "abc"]
    ) { res async throws in
      let updatedConfig = NotificationsConfigModel(userId: "123", token: "abc", enabled: true)
      let configs = try await dbNotificationConfigs()

      XCTAssertEqual(res.status, .noContent)
      XCTAssertEqual(configs, [updatedConfig])
    }
  }
}
