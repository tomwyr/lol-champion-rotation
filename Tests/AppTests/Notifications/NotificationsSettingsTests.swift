import XCTVapor

@testable import App

class GetNotificationsSettingsTests: AppTests {
  func testInvalidAuth() async throws {
    _ = try await testConfigureWith()

    try await app.test(
      .GET, "/notifications/settings",
      headers: reqHeaders()
    ) { res async in
      XCTAssertEqual(res.status, .unauthorized)
      XCTAssertBodyError(res.body, "Invalid device id")
    }
  }

  func testValidAuth() async throws {
    _ = try await testConfigureWith()

    try await app.test(
      .GET, "/notifications/settings",
      headers: reqHeaders(deviceId: "123")
    ) { res async in
      XCTAssertEqual(res.status, .notFound)
    }
  }

  func testNonExistingConfig() async throws {
    let existingConfig = NotificationsConfigModel(deviceId: "456", token: "def", enabled: true)

    _ = try await testConfigureWith(dbNotificationsConfigs: [existingConfig])

    try await app.test(
      .GET, "/notifications/settings",
      headers: reqHeaders(deviceId: "123")
    ) { res async throws in
      XCTAssertEqual(res.status, .notFound)
    }
  }

  func testExistingConfig() async throws {
    let existingConfig = NotificationsConfigModel(deviceId: "123", token: "abc", enabled: true)

    _ = try await testConfigureWith(dbNotificationsConfigs: [existingConfig])

    try await app.test(
      .GET, "/notifications/settings",
      headers: reqHeaders(deviceId: "123")
    ) { res async throws in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(res.body, ["enabled": true])
    }
  }
}

class PutNotificationsSettingsTests: AppTests {
  func testInvalidAuth() async throws {
    _ = try await testConfigureWith()

    try await app.test(
      .PUT, "/notifications/settings",
      headers: reqHeaders(),
      body: ["enabled": true]
    ) { res async in
      XCTAssertEqual(res.status, .unauthorized)
      XCTAssertBodyError(res.body, "Invalid device id")
    }
  }

  func testValidAuth() async throws {
    _ = try await testConfigureWith()

    try await app.test(
      .PUT, "/notifications/settings",
      headers: reqHeaders(deviceId: "123"),
      body: ["enabled": true]
    ) { res async in
      XCTAssertEqual(res.status, .noContent)
    }
  }

  func testAddingSettings() async throws {
    let existingConfig = NotificationsConfigModel(deviceId: "456", token: "def", enabled: false)

    _ = try await testConfigureWith(dbNotificationsConfigs: [existingConfig])

    try await app.test(
      .PUT, "/notifications/settings",
      headers: reqHeaders(deviceId: "123"),
      body: ["enabled": true]
    ) { res async throws in
      let addedConfig = NotificationsConfigModel(deviceId: "123", token: "", enabled: true)
      let configs = try await dbNotificationConfigs()

      XCTAssertEqual(res.status, .noContent)
      XCTAssertEqual(configs, [existingConfig, addedConfig])
    }
  }

  func testUpdatingSettings() async throws {
    let existingConfig = NotificationsConfigModel(deviceId: "123", token: "abc", enabled: false)

    _ = try await testConfigureWith(dbNotificationsConfigs: [existingConfig])

    try await app.test(
      .PUT, "/notifications/settings",
      headers: reqHeaders(deviceId: "123"),
      body: ["enabled": true]
    ) { res async throws in
      let updatedConfig = NotificationsConfigModel(deviceId: "123", token: "abc", enabled: true)
      let configs = try await dbNotificationConfigs()

      XCTAssertEqual(res.status, .noContent)
      XCTAssertEqual(configs, [updatedConfig])
    }
  }
}
