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
      appManagementKey: "123"
    )

    try await app.test(
      .POST, "/api/data/refresh",
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
      dbPatchVersions: [.init(value: "1.0.0")],
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
        res.body,
        [
          "rotation": ["rotationChanged": true],
          "version": ["latestVersion": "1.0.0", "versionChanged": false],
        ]
      )
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
      dbPatchVersions: [.init(value: "1.0.0")],
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
        res.body,
        [
          "rotation": ["rotationChanged": true],
          "version": ["latestVersion": "1.0.0", "versionChanged": false],
        ]
      )
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

      dbPatchVersions: [.init(value: "1.0.0")],
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
        res.body,
        [
          "rotation": ["rotationChanged": false],
          "version": ["latestVersion": "1.0.0", "versionChanged": false],
        ]
      )
    }
  }

  func testLatestRiotPatchVersionIsUsed() async throws {
    let httpClient = try await testConfigureWith(
      appManagementKey: "123",
      riotPatchVersions: ["15.22.1", "14.27.5", "15.23.5", "15.23.0", "15.22.8"],
      riotChampionsData: .init(data: [
        "Sett": .init(id: "Sett", key: "1", name: "Sett")
      ]),
      riotChampionsDataVersion: "15.23.5"
    )

    try await app.test(
      .POST, "/api/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      let latestChampionsDataUrl = requestUrls.riotChampions("15.23.5")
      XCTAssert(httpClient.requestedUrls.contains(latestChampionsDataUrl))
    }
  }

  func testInvalidRiotPatchVersionAreIgnored() async throws {
    let httpClient = try await testConfigureWith(
      appManagementKey: "123",
      riotPatchVersions: ["15.24.1a", "15.23.5", "lolpatch_7.20"],
      riotChampionsData: .init(data: [
        "Sett": .init(id: "Sett", key: "1", name: "Sett")
      ]),
      riotChampionsDataVersion: "15.23.5"
    )

    try await app.test(
      .POST, "/api/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      let latestChampionsDataUrl = requestUrls.riotChampions("15.23.5")
      XCTAssert(httpClient.requestedUrls.contains(latestChampionsDataUrl))
    }
  }

  func testLatestLocalVersionIsUsed() async throws {
    let httpClient = try await testConfigureWith(
      appManagementKey: "123",
      dbPatchVersions: [.init(value: "15.23.5")],
      riotChampionsData: .init(data: [
        "Sett": .init(id: "Sett", key: "1", name: "Sett")
      ]),
      riotChampionsDataVersion: "15.23.5"
    )

    try await app.test(
      .POST, "/api/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      let latestChampionsDataUrl = requestUrls.riotChampions("15.23.5")
      XCTAssert(httpClient.requestedUrls.contains(latestChampionsDataUrl))
    }
  }

  func testInvalidLocalVersionThrows() async throws {
    _ = try await testConfigureWith(
      appManagementKey: "123",
      dbPatchVersions: [
        .init(value: "15.24.1a"), .init(value: "15.23.5"), .init(value: "lolpatch_7.20"),
      ],
      riotChampionsData: .init(data: [
        "Sett": .init(id: "Sett", key: "1", name: "Sett")
      ]),
      riotChampionsDataVersion: "15.23.5"
    )

    try await app.test(
      .POST, "/api/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      XCTAssertEqual(res.status, .internalServerError)
    }
  }

  func testSavesPatchVersionWhenNoLocalExists() async throws {
    _ = try await testConfigureWith(
      appManagementKey: "123",
      dbPatchVersions: [],
      riotPatchVersions: ["15.23.5"],
      riotChampionsData: .init(data: [
        "Sett": .init(id: "Sett", key: "1", name: "Sett")
      ]),
      riotChampionsDataVersion: "15.23.5"
    )

    try await app.test(
      .POST, "/api/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async throws in
      let versions = try await localPatchVersions()
      XCTAssertEqual(versions, ["15.23.5"])
    }
  }

  func testSavesPatchVersionWhenOlderLocalExists() async throws {
    _ = try await testConfigureWith(
      appManagementKey: "123",
      dbPatchVersions: [.init(value: "14.0.0")],
      riotPatchVersions: ["15.23.5"],
      riotChampionsData: .init(data: [
        "Sett": .init(id: "Sett", key: "1", name: "Sett")
      ]),
      riotChampionsDataVersion: "15.23.5"
    )

    try await app.test(
      .POST, "/api/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async throws in
      let versions = try await localPatchVersions()
      XCTAssertEqual(versions, ["14.0.0", "15.23.5"])
    }
  }

  func testIgnoresPatchVersionWhenNewerLocalExists() async throws {
    _ = try await testConfigureWith(
      appManagementKey: "123",
      dbPatchVersions: [.init(value: "16.0.0")],
      riotPatchVersions: ["15.23.5"],
      riotChampionsData: .init(data: [
        "Sett": .init(id: "Sett", key: "1", name: "Sett")
      ]),
      riotChampionsDataVersion: "16.0.0"
    )

    try await app.test(
      .POST, "/api/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async throws in
      let versions = try await localPatchVersions()
      XCTAssertEqual(versions, ["16.0.0"])
    }
  }
}

extension RefreshDataTests {
  func localPatchVersions() async throws -> [String?] {
    try await PatchVersionModel.query(on: app.db).all().map(\.value)
  }
}
