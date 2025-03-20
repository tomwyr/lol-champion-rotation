import XCTVapor

@testable import App
@testable import FCM

class RefreshDataNotificationsTests: AppTests {
  func testRotationChangedRecipients() async throws {
    let (_, fcm) = try await testConfigureWith(
      appManagementKey: "123",
      dbRegularRotations: [
        .init(
          observedAt: Date.now,
          champions: ["Sett", "Senna"]
        )
      ],
      dbPatchVersions: [.init(value: "1")],
      dbNotificationsConfigs: [
        .init(userId: "1", token: "1", rotationChanged: true, championsAvailable: false),
        .init(userId: "2", token: "2", rotationChanged: true, championsAvailable: true),
        .init(userId: "3", token: "3", rotationChanged: false, championsAvailable: true),
        .init(userId: "4", token: "4", rotationChanged: false, championsAvailable: false),
      ],
      riotPatchVersions: ["1"],
      riotChampionRotationsData: .init(
        freeChampionIds: [1, 2],
        freeChampionIdsForNewPlayers: [],
        maxNewPlayerLevel: 10
      ),
      riotChampionsData: .init(data: [
        "Sett": .init(id: "Sett", key: "1", name: "Sett"),
        "Garen": .init(id: "Garen", key: "2", name: "Garen"),
        "Nocturne": .init(id: "Nocturne", key: "3", name: "Nocturne"),
        "Senna": .init(id: "Senna", key: "4", name: "Senna"),
      ])
    )

    try await app.test(
      .GET, "/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async throws in
      XCTAssertEqual(res.status, .ok)
      let tokens = fcm.rotationChangedMessages.map(\.token)
      XCTAssertEqual(tokens, ["1", "2"])
    }
  }

  func testRotationChangedContent() async throws {
    let (_, fcm) = try await testConfigureWith(
      appManagementKey: "123",
      dbRegularRotations: [
        .init(
          observedAt: Date.now,
          champions: ["Sett", "Senna"]
        )
      ],
      dbPatchVersions: [.init(value: "1")],
      dbNotificationsConfigs: [
        .init(userId: "1", token: "1", rotationChanged: true, championsAvailable: false)
      ],
      riotPatchVersions: ["1"],
      riotChampionRotationsData: .init(
        freeChampionIds: [1, 2],
        freeChampionIdsForNewPlayers: [],
        maxNewPlayerLevel: 10
      ),
      riotChampionsData: .init(data: [
        "Sett": .init(id: "Sett", key: "1", name: "Sett"),
        "Garen": .init(id: "Garen", key: "2", name: "Garen"),
      ])
    )

    try await app.test(
      .GET, "/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async throws in
      XCTAssertEqual(res.status, .ok)
      XCTAssertEqual(fcm.rotationChangedMessages.count, 1)
      let notification = fcm.rotationChangedMessages[0].notification!
      XCTAssertEqual(notification.title, "Rotation Changed")
      XCTAssertEqual(notification.body, "New champion rotation is now available")
    }
  }

  func testChampionsAvailableRecipients() async throws {
    let (_, fcm) = try await testConfigureWith(
      appManagementKey: "123",
      dbRegularRotations: [
        .init(
          observedAt: Date.now,
          champions: ["Sett", "Senna"]
        )
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Sett", name: "Sett"),
        .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
        .init(id: uuid("3"), riotId: "Nocturne", name: "Nocturne"),
        .init(id: uuid("4"), riotId: "Senna", name: "Senna"),
      ],
      dbPatchVersions: [.init(value: "1")],
      dbNotificationsConfigs: [
        .init(userId: "1", token: "1", rotationChanged: true, championsAvailable: false),
        .init(userId: "2", token: "2", rotationChanged: true, championsAvailable: true),
        .init(userId: "3", token: "3", rotationChanged: false, championsAvailable: true),
        .init(userId: "4", token: "4", rotationChanged: false, championsAvailable: true),
      ],
      dbUserWatchlists: [
        .init(userId: "1", champions: [uuidString("1")]),
        .init(userId: "2", champions: [uuidString("1"), uuidString("3")]),
        .init(userId: "3", champions: [uuidString("1"), uuidString("2")]),
        .init(userId: "4", champions: [uuidString("1"), uuidString("2"), uuidString("4")]),
      ],
      riotPatchVersions: ["1"],
      riotChampionRotationsData: .init(
        freeChampionIds: [1, 2],
        freeChampionIdsForNewPlayers: [],
        maxNewPlayerLevel: 10
      ),
      riotChampionsData: .init(data: [
        "Sett": .init(id: "Sett", key: "1", name: "Sett"),
        "Garen": .init(id: "Garen", key: "2", name: "Garen"),
        "Nocturne": .init(id: "Nocturne", key: "3", name: "Nocturne"),
        "Senna": .init(id: "Senna", key: "4", name: "Senna"),
      ])
    )

    try await app.test(
      .GET, "/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      let tokens = fcm.championsAvailableMessages.map(\.token)
      XCTAssertEqual(tokens, ["2", "3", "4"])
    }
  }

  func testChampionsAvailableContent() async throws {
    let (_, fcm) = try await testConfigureWith(
      appManagementKey: "123",
      dbRegularRotations: [
        .init(
          observedAt: Date.now,
          champions: ["Sett", "Senna"]
        )
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Sett", name: "Sett"),
        .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
        .init(id: uuid("3"), riotId: "Nocturne", name: "Nocturne"),
        .init(id: uuid("4"), riotId: "Senna", name: "Senna"),
      ],
      dbPatchVersions: [.init(value: "1")],
      dbNotificationsConfigs: [
        .init(userId: "1", token: "1", rotationChanged: false, championsAvailable: true),
        .init(userId: "2", token: "2", rotationChanged: false, championsAvailable: true),
        .init(userId: "3", token: "3", rotationChanged: false, championsAvailable: true),
      ],
      dbUserWatchlists: [
        .init(userId: "1", champions: [uuidString("1")]),
        .init(userId: "2", champions: [uuidString("2"), uuidString("3")]),
        .init(
          userId: "3",
          champions: [uuidString("1"), uuidString("2"), uuidString("3"), uuidString("4")]
        ),
      ],
      riotPatchVersions: ["1"],
      riotChampionRotationsData: .init(
        freeChampionIds: [1, 2, 3, 4],
        freeChampionIdsForNewPlayers: [],
        maxNewPlayerLevel: 10
      ),
      riotChampionsData: .init(data: [
        "Sett": .init(id: "Sett", key: "1", name: "Sett"),
        "Garen": .init(id: "Garen", key: "2", name: "Garen"),
        "Nocturne": .init(id: "Nocturne", key: "3", name: "Nocturne"),
        "Senna": .init(id: "Senna", key: "4", name: "Senna"),
      ])
    )

    try await app.test(
      .GET, "/data/refresh",
      headers: ["Authorization": "Bearer 123"]
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      let notifications = fcm.championsAvailableMessages
        .sorted(byComparable: \.token)
        .map(\.notification!)
      XCTAssertEqual(fcm.championsAvailableMessages.count, 3)
      XCTAssertEqual(notifications[0].title, "Champion Available")
      XCTAssertEqual(notifications[0].body, "Sett is now available in the rotation")
      XCTAssertEqual(notifications[1].title, "Champions Available")
      XCTAssertEqual(notifications[1].body, "Garen and Nocturne are now available in the rotation")
      XCTAssertEqual(notifications[2].title, "Champions Available")
      XCTAssertEqual(
        notifications[2].body, "Garen, Nocturne and 2 more are now available in the rotation"
      )
    }
  }
}

extension MockFcmDispatcher {
  var rotationChangedMessages: [FCMMessageDefault] {
    sentMessages.filter { $0.data == rotationChangedData }
  }

  var championsAvailableMessages: [FCMMessageDefault] {
    sentMessages.filter { $0.data == championsAvailableData }
  }
}
