import XCTVapor

@testable import App

class RefreshDataTests: AppTests {
  func testNoToken() async throws {
    _ = try await testConfigureWith(appManagementKey: "123")

    try await app.test(
      .POST, "/api/data/refresh"
    ) { res async in
      XCTAssertEqual(res.status, .unauthorized)
      XCTAssertBodyError(res.body, "Invalid auth token")
    }
  }

  func testInvalidToken() async throws {
    _ = try await testConfigureWith(appManagementKey: "abc")

    try await app.test(
      .POST, "/api/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      XCTAssertEqual(res.status, .unauthorized)
      XCTAssertBodyError(res.body, "Invalid auth token")
    }
  }

  func testValidToken() async throws {
    _ = try await testConfigureWith(
      appManagementKey: "123",
      dbPatchVersions: [.init(value: "1")],
      riotPatchVersions: ["1"]
    )

    try await app.test(
      .POST, "/api/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      XCTAssertEqual(res.status, .ok)
    }
  }

  func testRotationChampionsChanged() async throws {
    _ = try await testConfigureWith(
      appManagementKey: "123",
      dbChampionRotation: .init(
        beginnerMaxLevel: 10,
        beginnerChampions: ["Nocturne"],
        regularChampions: ["Sett", "Sett"]
      ),
      dbPatchVersions: [.init(value: "1")],
      riotPatchVersions: ["1"],
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
      .POST, "/api/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body, at: "rotation",
        ["rotationChanged": true]
      )
    }
  }

  func testRotationMaxLevelChanged() async throws {
    _ = try await testConfigureWith(
      appManagementKey: "123",
      dbChampionRotation: .init(
        beginnerMaxLevel: 5,
        beginnerChampions: ["Nocturne"],
        regularChampions: ["Sett", "Garen"]
      ),
      dbPatchVersions: [.init(value: "1")],
      riotPatchVersions: ["1"],
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
      .POST, "/api/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body, at: "rotation",
        ["rotationChanged": true]
      )
    }
  }

  func testRotationDidNotChange() async throws {
    _ = try await testConfigureWith(
      appManagementKey: "123",
      dbChampionRotation: .init(
        beginnerMaxLevel: 10,
        beginnerChampions: ["Nocturne"],
        regularChampions: ["Sett", "Garen"]
      ),
      dbPatchVersions: [.init(value: "1")],
      riotPatchVersions: ["1"],
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
      .POST, "/api/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body, at: "rotation",
        ["rotationChanged": false])
    }
  }

  func testMultipleLocalVersions() async throws {
    let httpClient = try await testConfigureWith(
      appManagementKey: "123",
      dbPatchVersions: [
        .init(value: "15.23.5"),
        .init(value: "15.23.0"),
        .init(value: "15.22.8"),
      ],
      riotPatchVersions: ["15.23.5"]
    )

    try await app.test(
      .POST, "/api/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      let latestChampionsUrl = requestUrls.riotChampions("15.23.5")
      XCTAssert(httpClient.requestedUrls.contains(latestChampionsUrl))
    }
  }

  func testMultipleRiotVersions() async throws {
    let httpClient = try await testConfigureWith(
      appManagementKey: "123",
      dbPatchVersions: [.init(value: "1")],
      riotPatchVersions: ["15.23.5", "15.23.0", "15.22.8"]
    )

    try await app.test(
      .POST, "/api/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      let latestChampionsUrl = requestUrls.riotChampions("15.23.5")
      XCTAssert(httpClient.requestedUrls.contains(latestChampionsUrl))
    }
  }

  func testDifferentVersions() async throws {
    _ = try await testConfigureWith(
      appManagementKey: "123",
      dbPatchVersions: [.init(value: "14.0.0")],
      riotPatchVersions: ["15.23.5"]
    )

    try await app.test(
      .POST, "/api/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async throws in
      let versions = try await localPatchVersions()
      XCTAssertEqual(versions, ["14.0.0", "15.23.5"])
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body, at: "version",
        ["latestVersion": "15.23.5", "versionChanged": true]
      )
    }
  }

  func testIdenticalVersions() async throws {
    _ = try await testConfigureWith(
      appManagementKey: "123",
      dbPatchVersions: [.init(value: "15.23.5")],
      riotPatchVersions: ["15.23.5"]
    )

    try await app.test(
      .POST, "/api/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async throws in
      let versions = try await localPatchVersions()
      XCTAssertEqual(versions, ["15.23.5"])
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body, at: "version",
        ["latestVersion": "15.23.5", "versionChanged": false]
      )
    }
  }
}

extension RefreshDataTests {
  func localPatchVersions() async throws -> [String?] {
    try await PatchVersionModel.query(on: app.db).all().map(\.value)
  }
}