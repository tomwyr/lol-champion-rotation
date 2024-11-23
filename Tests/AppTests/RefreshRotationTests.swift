import XCTVapor

@testable import App

class RefreshRotationTests: AppTests {
  func testNoToken() async throws {
    _ = try await testConfigureWith(appManagementKey: "123")

    try await app.test(
      .POST, "/api/rotation/refresh"
    ) { res async in
      XCTAssertEqual(res.status, .unauthorized)
      XCTAssertBodyError(res.body, "Invalid auth token")
    }
  }

  func testInvalidToken() async throws {
    _ = try await testConfigureWith(appManagementKey: "abc")

    try await app.test(
      .POST, "/api/rotation/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      XCTAssertEqual(res.status, .unauthorized)
      XCTAssertBodyError(res.body, "Invalid auth token")
    }
  }

  func testValidToken() async throws {
    _ = try await testConfigureWith(
      appManagementKey: "123"
    )

    try await app.test(
      .POST, "/api/rotation/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      XCTAssertEqual(res.status, .ok)
    }
  }

  func testResultWhenRotationChampionsChanged() async throws {
    _ = try await testConfigureWith(
      appManagementKey: "123",
      dbChampionRotation: .init(
        beginnerMaxLevel: 10,
        beginnerChampions: ["Nocturne"],
        regularChampions: ["Sett", "Sett"]
      ),
      riotChampionRotationsData: .init(
        freeChampionIds: [1, 2],
        freeChampionIdsForNewPlayers: [3],
        maxNewPlayerLevel: 10
      ),
      riotChampionsData: .init(data: [
        "Sett": .init(id: "Sett", key: "1", name: "Sett"),
        "Garen": .init(id: "Garen", key: "2", name: "Garen"),
        "Nocturne": .init(id: "Nocturne", key: "3", name: "Nocturne"),
      ])
    )

    try await app.test(
      .POST, "/api/rotation/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(res.body, ["rotationChanged": true])
    }
  }

  func testResultWhenRotationMaxLevelChanged() async throws {
    _ = try await testConfigureWith(
      appManagementKey: "123",
      dbChampionRotation: .init(
        beginnerMaxLevel: 5,
        beginnerChampions: ["Nocturne"],
        regularChampions: ["Sett", "Garen"]
      ),
      riotChampionRotationsData: .init(
        freeChampionIds: [1, 2],
        freeChampionIdsForNewPlayers: [3],
        maxNewPlayerLevel: 10
      ),
      riotChampionsData: .init(data: [
        "Sett": .init(id: "Sett", key: "1", name: "Sett"),
        "Garen": .init(id: "Garen", key: "2", name: "Garen"),
        "Nocturne": .init(id: "Nocturne", key: "3", name: "Nocturne"),
      ])
    )

    try await app.test(
      .POST, "/api/rotation/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(res.body, ["rotationChanged": true])
    }
  }

  func testResultWhenRotationDidNotChange() async throws {
    _ = try await testConfigureWith(
      appManagementKey: "123",
      dbChampionRotation: .init(
        beginnerMaxLevel: 10,
        beginnerChampions: ["Nocturne"],
        regularChampions: ["Sett", "Garen"]
      ),
      riotChampionRotationsData: .init(
        freeChampionIds: [1, 2],
        freeChampionIdsForNewPlayers: [3],
        maxNewPlayerLevel: 10
      ),
      riotChampionsData: .init(data: [
        "Sett": .init(id: "Sett", key: "1", name: "Sett"),
        "Garen": .init(id: "Garen", key: "2", name: "Garen"),
        "Nocturne": .init(id: "Nocturne", key: "3", name: "Nocturne"),
      ])
    )

    try await app.test(
      .POST, "/api/rotation/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(res.body, ["rotationChanged": false])
    }
  }

  func testLatestPatchVersionIsUsed() async throws {
    let httpClient = try await testConfigureWith(
      appManagementKey: "123",
      riotPatchVersions: ["15.22.1", "14.27.5", "15.23.5", "15.23.0", "15.22.8"],
      riotChampionsData: .init(data: [
        "Sett": .init(id: "Sett", key: "1", name: "Sett")
      ]),
      riotChampionsDataVersion: "15.23.5"
    )

    try await app.test(
      .POST, "/api/rotation/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      let latestChampionsDataUrl = requestUrls.riotChampions("15.23.5")
      XCTAssert(httpClient.requestedUrls.contains(latestChampionsDataUrl))
    }
  }

  func testInvalidPatchVersionAreIgnored() async throws {
    let httpClient = try await testConfigureWith(
      appManagementKey: "123",
      riotPatchVersions: ["15.24.1a", "15.23.5", "lolpatch_7.20"],
      riotChampionsData: .init(data: [
        "Sett": .init(id: "Sett", key: "1", name: "Sett")
      ]),
      riotChampionsDataVersion: "15.23.5"
    )

    try await app.test(
      .POST, "/api/rotation/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      let latestChampionsDataUrl = requestUrls.riotChampions("15.23.5")
      XCTAssert(httpClient.requestedUrls.contains(latestChampionsDataUrl))
    }
  }
}
