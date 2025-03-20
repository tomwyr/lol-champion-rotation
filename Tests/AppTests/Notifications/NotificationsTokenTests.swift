import XCTVapor

@testable import App

class PutNotificationsTokenTests: AppTests {
  func testInvalidAuth() async throws {
    _ = try await testConfigureWith()

    try await app.test(
      .PUT, "/notifications/token",
      headers: reqHeaders(),
      body: ["token": "123"]
    ) { res async in
      XCTAssertEqual(res.status, .unauthorized)
    }
  }

  func testValidAuth() async throws {
    _ = try await testConfigureWith()

    try await app.test(
      .PUT, "/notifications/token",
      headers: reqHeaders(accessToken: mobileToken),
      body: ["token": "abc"]
    ) { res async in
      XCTAssertEqual(res.status, .noContent)
    }
  }

  func testAddingNewToken() async throws {
    let existingConfig = NotificationsConfigModel(
      userId: "123", token: "def",
      rotationChanged: true, championsAvailable: true
    )

    _ = try await testConfigureWith(dbNotificationsConfigs: [existingConfig])

    try await app.test(
      .PUT, "/notifications/token",
      headers: reqHeaders(accessToken: mobileToken),
      body: ["token": "abc"]
    ) { res async throws in
      let addedConfig = NotificationsConfigModel(
        userId: mobileUserId, token: "abc",
        rotationChanged: false, championsAvailable: false
      )
      let configs = try await dbNotificationConfigs()

      XCTAssertEqual(res.status, .noContent)
      XCTAssertEqual(configs, [existingConfig, addedConfig])
    }
  }

  func testUpdatingExistingToken() async throws {
    let existingConfig = NotificationsConfigModel(
      userId: mobileUserId, token: "def",
      rotationChanged: true, championsAvailable: true
    )

    _ = try await testConfigureWith(dbNotificationsConfigs: [existingConfig])

    try await app.test(
      .PUT, "/notifications/token",
      headers: reqHeaders(accessToken: mobileToken),
      body: ["token": "abc"]
    ) { res async throws in
      let updatedConfig = NotificationsConfigModel(
        userId: mobileUserId, token: "abc",
        rotationChanged: true, championsAvailable: true
      )
      let configs = try await dbNotificationConfigs()

      XCTAssertEqual(res.status, .noContent)
      XCTAssertEqual(configs, [updatedConfig])
    }
  }
}
