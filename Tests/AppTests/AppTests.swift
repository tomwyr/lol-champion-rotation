import XCTVapor

@testable import App

final class AppTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        app = try await Application.make(.testing)
    }

    override func tearDown() async throws {
        try await app.asyncShutdown()
        app = nil
    }

    func testRefreshRotationWithNoToken() async throws {
        try await testConfigureWith(appManagementKey: "123")

        try await app.test(
            .POST, "/rotation/refresh"
        ) { res async in
            XCTAssertEqual(res.status, .unauthorized)
            XCTAssertBodyError(res.body, "Invalid auth token")
        }
    }

    func testRefreshRotationWithInvalidToken() async throws {
        try await testConfigureWith(appManagementKey: "abc")

        try await app.test(
            .POST, "/rotation/refresh",
            headers: ["Authorization": "Bearer 123"]
        ) { res async in
            XCTAssertEqual(res.status, .unauthorized)
            XCTAssertBodyError(res.body, "Invalid auth token")
        }
    }

    func testRefreshRotationWithValidToken() async throws {
        try await testConfigureWith(appManagementKey: "123")

        try await app.test(
            .POST, "/rotation/refresh",
            headers: ["Authorization": "Bearer 123"]
        ) { res async in
            XCTAssertEqual(res.status, .ok)
        }
    }

    func testRefreshRotationWhenRotationChanged() async throws {
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

    func testRefreshRotationWhenRotationDidNotChanged() async throws {
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
