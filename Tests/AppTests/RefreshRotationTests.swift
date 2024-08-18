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

  func testResultWhenRotationChanged() async throws {
    let dbChampionIds = ["Sett", "Garen"]

    try await testConfigureWith(
      appManagementKey: "123",
      dbChampionRotation: { model in
        model.championIds = dbChampionIds
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
    let dbChampionIds = ["Sett", "Garen", "Nocturne"]

    try await testConfigureWith(
      appManagementKey: "123",
      dbChampionRotation: { model in
        model.championIds = dbChampionIds
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
