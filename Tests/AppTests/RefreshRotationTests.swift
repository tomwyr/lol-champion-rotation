import XCTVapor

@testable import App

class RefreshRotationTests: AppTests {
  func testNoToken() async throws {
    try await testConfigureWith(appManagementKey: "123")

    try await app.test(
      .POST, "/rotation/refresh"
    ) { res async in
      XCTAssertEqual(res.status, .unauthorized)
      XCTAssertBodyError(res.body, "Invalid auth token")
    }
  }

  func testInvalidToken() async throws {
    try await testConfigureWith(appManagementKey: "abc")

    try await app.test(
      .POST, "/rotation/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      XCTAssertEqual(res.status, .unauthorized)
      XCTAssertBodyError(res.body, "Invalid auth token")
    }
  }

  func testValidToken() async throws {
    try await testConfigureWith(appManagementKey: "123")

    try await app.test(
      .POST, "/rotation/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      XCTAssertEqual(res.status, .ok)
    }
  }

  func testResultWhenRotationChampionsChanged() async throws {
    try await testConfigureWith(
      appManagementKey: "123",
      dbChampionRotation: { model in
        model.beginnerMaxLevel = 10
        model.beginnerChampions = [.init(id: "Nocturne", name: "Nocturne")]
        model.regularChampions = [.init(id: "Sett", name: "Sett")]
      },
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
      .POST, "/rotation/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(res.body, ["rotationChanged": true])
    }
  }

  func testResultWhenRotationMaxLevelChanged() async throws {
    try await testConfigureWith(
      appManagementKey: "123",
      dbChampionRotation: { model in
        model.beginnerMaxLevel = 5
        model.beginnerChampions = [.init(id: "Nocturne", name: "Nocturne")]
        model.regularChampions = [
          .init(id: "Sett", name: "Sett"),
          .init(id: "Garen", name: "Garen"),
        ]
      },
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
      .POST, "/rotation/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(res.body, ["rotationChanged": true])
    }
  }

  func testResultWhenRotationDidNotChange() async throws {
    try await testConfigureWith(
      appManagementKey: "123",
      dbChampionRotation: { model in
        model.beginnerMaxLevel = 10
        model.beginnerChampions = [.init(id: "Nocturne", name: "Nocturne")]
        model.regularChampions = [
          .init(id: "Sett", name: "Sett"),
          .init(id: "Garen", name: "Garen"),
        ]
      },
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
      .POST, "/rotation/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(res.body, ["rotationChanged": false])
    }
  }
}
