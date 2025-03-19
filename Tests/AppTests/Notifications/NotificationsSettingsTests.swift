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
    }
  }

  func testValidAuth() async throws {
    _ = try await testConfigureWith()

    try await app.test(
      .GET, "/notifications/settings",
      headers: reqHeaders(accessToken: mobileToken)
    ) { res async in
      XCTAssertEqual(res.status, .notFound)
    }
  }

  func testNonExistingConfig() async throws {
    let existingConfig = NotificationsConfigModel(
      userId: "123", token: "def",
      currentRotation: true, observedChampions: true
    )

    _ = try await testConfigureWith(dbNotificationsConfigs: [existingConfig])

    try await app.test(
      .GET, "/notifications/settings",
      headers: reqHeaders(accessToken: mobileToken)
    ) { res async throws in
      XCTAssertEqual(res.status, .notFound)
    }
  }

  func testExistingConfig() async throws {
    let existingConfig = NotificationsConfigModel(
      userId: mobileUserId, token: "abc",
      currentRotation: true, observedChampions: true
    )

    _ = try await testConfigureWith(dbNotificationsConfigs: [existingConfig])

    try await app.test(
      .GET, "/notifications/settings",
      headers: reqHeaders(accessToken: mobileToken)
    ) { res async throws in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        ["currentRotation": true, "observedChampions": true]
      )
    }
  }
}

class PutNotificationsSettingsTests: AppTests {
  func testInvalidAuth() async throws {
    _ = try await testConfigureWith()

    try await app.test(
      .PUT, "/notifications/settings",
      headers: reqHeaders(),
      body: ["currentRotation": true, "observedChampions": true]
    ) { res async in
      XCTAssertEqual(res.status, .unauthorized)
    }
  }

  func testValidAuth() async throws {
    _ = try await testConfigureWith()

    try await app.test(
      .PUT, "/notifications/settings",
      headers: reqHeaders(accessToken: mobileToken),
      body: ["currentRotation": true, "observedChampions": true]
    ) { res async in
      XCTAssertEqual(res.status, .noContent)
    }
  }

  func testAddingSettings() async throws {
    let existingConfig = NotificationsConfigModel(
      userId: "123", token: "def",
      currentRotation: false, observedChampions: false
    )

    _ = try await testConfigureWith(dbNotificationsConfigs: [existingConfig])

    try await app.test(
      .PUT, "/notifications/settings",
      headers: reqHeaders(accessToken: mobileToken),
      body: ["currentRotation": true, "observedChampions": true]
    ) { res async throws in
      let addedConfig = NotificationsConfigModel(
        userId: mobileUserId, token: "",
        currentRotation: true, observedChampions: true
      )
      let configs = try await dbNotificationConfigs()

      XCTAssertEqual(res.status, .noContent)
      XCTAssertEqual(configs, [existingConfig, addedConfig])
    }
  }

  func testUpdatingSettings() async throws {
    let existingConfig = NotificationsConfigModel(
      userId: mobileUserId, token: "abc",
      currentRotation: false, observedChampions: true
    )

    _ = try await testConfigureWith(dbNotificationsConfigs: [existingConfig])

    try await app.test(
      .PUT, "/notifications/settings",
      headers: reqHeaders(accessToken: mobileToken),
      body: ["currentRotation": true, "observedChampions": false]
    ) { res async throws in
      let updatedConfig = NotificationsConfigModel(
        userId: mobileUserId, token: "abc",
        currentRotation: true, observedChampions: false
      )
      let configs = try await dbNotificationConfigs()

      XCTAssertEqual(res.status, .noContent)
      XCTAssertEqual(configs, [updatedConfig])
    }
  }
}
