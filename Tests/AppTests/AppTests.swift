import XCTVapor

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
        try testConfigureWith(appManagementKey: "123")

        try await app.test(
            .POST, "/rotation/refresh"
        ) { res async in
            XCTAssertEqual(res.status, .unauthorized)
            XCTAssertBodyError(res.body, "Invalid auth token")
        }
    }

    func testRefreshRotationWithInvalidToken() async throws {
        try testConfigureWith(appManagementKey: "abc")

        try await app.test(
            .POST, "/rotation/refresh",
            headers: ["Authorization": "Bearer 123"]
        ) { res async in
            XCTAssertEqual(res.status, .unauthorized)
            XCTAssertBodyError(res.body, "Invalid auth token")
        }
    }

    func testRefreshRotationWithValidToken() async throws {
        try testConfigureWith(appManagementKey: "123")

        try await app.test(
            .POST, "/rotation/refresh",
            headers: ["Authorization": "Bearer 123"]
        ) { res async in
            XCTAssertEqual(res.status, .ok)
        }
    }
}
