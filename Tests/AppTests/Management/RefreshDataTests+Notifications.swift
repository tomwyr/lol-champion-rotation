import Foundation
import Testing

@testable import App
@testable import FCM

extension AppTests {
  @Suite(.serialized) struct RefreshDataNotificationsTests {
    @Test func rotationChangedRecipients() async throws {
      try await withApp { app in
        let mocks = try await app.testConfigureWith(
          appManagementKey: "123",
          dbRegularRotations: [
            .init(
              observedAt: Date.now,
              champions: ["Sett", "Senna"],
              slug: "s1w1",
            )
          ],
          dbPatchVersions: [.init(value: "1")],
          dbNotificationsConfigs: [
            .init(
              userId: "1", token: "1",
              rotationChanged: true, championsAvailable: false, championReleased: false,
            ),
            .init(
              userId: "2", token: "2",
              rotationChanged: true, championsAvailable: true, championReleased: false,
            ),
            .init(
              userId: "3", token: "3",
              rotationChanged: false, championsAvailable: true, championReleased: false,
            ),
            .init(
              userId: "4", token: "4",
              rotationChanged: false, championsAvailable: false, championReleased: false,
            ),
            .init(
              userId: "5", token: "5",
              rotationChanged: false, championsAvailable: false, championReleased: true,
            ),
            .init(
              userId: "6", token: "6",
              rotationChanged: true, championsAvailable: false, championReleased: true,
            ),
          ],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          riotPatchVersions: ["1"],
          riotChampionRotationsData: .init(
            freeChampionIds: [1, 2],
            freeChampionIdsForNewPlayers: [],
            maxNewPlayerLevel: 10,
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
          #expect(res.status == .ok)
          let tokens = mocks.fcm.rotationChangedMessages.map(\.token)
          #expect(tokens == ["1", "2", "6"])
        }
      }
    }

    @Test func rotationChangedContent() async throws {
      try await withApp { app in
        let mocks = try await app.testConfigureWith(
          appManagementKey: "123",
          dbRegularRotations: [
            .init(
              observedAt: Date.now,
              champions: ["Sett", "Senna"],
              slug: "s1w1",
            )
          ],
          dbPatchVersions: [.init(value: "1")],
          dbNotificationsConfigs: [
            .init(
              userId: "1", token: "1",
              rotationChanged: true, championsAvailable: false, championReleased: false,
            )
          ],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          riotPatchVersions: ["1"],
          riotChampionRotationsData: .init(
            freeChampionIds: [1, 2],
            freeChampionIdsForNewPlayers: [],
            maxNewPlayerLevel: 10,
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
          #expect(res.status == .ok)
          #expect(mocks.fcm.rotationChangedMessages.count == 1)
          let notification = mocks.fcm.rotationChangedMessages[0].notification!
          #expect(notification.title == "Rotation Changed")
          #expect(notification.body == "New champion rotation is now available")
        }
      }
    }

    @Test func championsAvailableRecipients() async throws {
      try await withApp { app in
        let mocks = try await app.testConfigureWith(
          appManagementKey: "123",
          dbRegularRotations: [
            .init(
              observedAt: Date.now,
              champions: ["Sett", "Senna"],
              slug: "s1w1",
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
            .init(
              userId: "1", token: "1",
              rotationChanged: true, championsAvailable: false, championReleased: false,
            ),
            .init(
              userId: "2", token: "2",
              rotationChanged: true, championsAvailable: true, championReleased: false,
            ),
            .init(
              userId: "3", token: "3",
              rotationChanged: false, championsAvailable: true, championReleased: false,
            ),
            .init(
              userId: "4", token: "4",
              rotationChanged: false, championsAvailable: true, championReleased: false,
            ),
            .init(
              userId: "5", token: "5",
              rotationChanged: false, championsAvailable: true, championReleased: false,
            ),
            .init(
              userId: "6", token: "6",
              rotationChanged: false, championsAvailable: true, championReleased: true,
            ),
          ],
          dbUserWatchlists: [
            .init(userId: "1", champions: [uuidString("1")]),
            .init(userId: "2", champions: [uuidString("1"), uuidString("3")]),
            .init(userId: "3", champions: [uuidString("1"), uuidString("2")]),
            .init(userId: "4", champions: [uuidString("1"), uuidString("2"), uuidString("4")]),
            .init(userId: "5", champions: [uuidString("3")]),
            .init(userId: "6", champions: [uuidString("2"), uuidString("4")]),
          ],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          riotPatchVersions: ["1"],
          riotChampionRotationsData: .init(
            freeChampionIds: [1, 2],
            freeChampionIdsForNewPlayers: [],
            maxNewPlayerLevel: 10,
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
          #expect(res.status == .ok)
          let tokens = mocks.fcm.championsAvailableMessages.compactMap(\.token).sorted()
          #expect(tokens == ["2", "3", "4", "6"])
        }
      }
    }

    @Test func championsAvailableContent() async throws {
      try await withApp { app in
        let mocks = try await app.testConfigureWith(
          appManagementKey: "123",
          dbRegularRotations: [
            .init(
              observedAt: Date.now,
              champions: ["Sett", "Senna"],
              slug: "s1w1",
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
            .init(
              userId: "1", token: "1",
              rotationChanged: false, championsAvailable: true, championReleased: false,
            ),
            .init(
              userId: "2", token: "2",
              rotationChanged: false, championsAvailable: true, championReleased: false,
            ),
            .init(
              userId: "3", token: "3",
              rotationChanged: false, championsAvailable: true, championReleased: false,
            ),
          ],
          dbUserWatchlists: [
            .init(userId: "1", champions: [uuidString("1")]),
            .init(userId: "2", champions: [uuidString("2"), uuidString("3")]),
            .init(
              userId: "3",
              champions: [uuidString("1"), uuidString("2"), uuidString("3"), uuidString("4")]
            ),
          ],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          riotPatchVersions: ["1"],
          riotChampionRotationsData: .init(
            freeChampionIds: [1, 2, 3, 4],
            freeChampionIdsForNewPlayers: [],
            maxNewPlayerLevel: 10,
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
          #expect(res.status == .ok)
          let notifications = mocks.fcm.championsAvailableMessages
            .sorted(byComparable: \.token)
            .map(\.notification!)
          #expect(mocks.fcm.championsAvailableMessages.count == 3)
          #expect(notifications[0].title == "Champion Available")
          #expect(notifications[0].body == "Sett is now available in the rotation")
          #expect(notifications[1].title == "Champions Available")
          #expect(notifications[1].body == "Garen and Nocturne are now available in the rotation")
          #expect(notifications[2].title == "Champions Available")
          #expect(
            notifications[2].body == "Garen, Nocturne and 2 more are now available in the rotation"
          )
        }
      }
    }

    @Test func championReleasedRecipients() async throws {
      try await withApp { app in
        let mocks = try await app.testConfigureWith(
          appManagementKey: "123",
          dbRegularRotations: [
            .init(
              observedAt: Date.now,
              champions: ["Sett", "Senna"],
              slug: "s1w1",
            )
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Sett", name: "Sett")
          ],
          dbPatchVersions: [.init(value: "1")],
          dbNotificationsConfigs: [
            .init(
              userId: "1", token: "1",
              rotationChanged: true, championsAvailable: false, championReleased: true,
            ),
            .init(
              userId: "2", token: "2",
              rotationChanged: true, championsAvailable: true, championReleased: true,
            ),
            .init(
              userId: "3", token: "3",
              rotationChanged: false, championsAvailable: true, championReleased: true,
            ),
            .init(
              userId: "4", token: "4",
              rotationChanged: true, championsAvailable: false, championReleased: false,
            ),
            .init(
              userId: "5", token: "5",
              rotationChanged: false, championsAvailable: false, championReleased: false,
            ),
            .init(
              userId: "6", token: "6",
              rotationChanged: false, championsAvailable: false, championReleased: true,
            ),
          ],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          riotPatchVersions: ["1"],
          riotChampionRotationsData: .init(
            freeChampionIds: [1, 2],
            freeChampionIdsForNewPlayers: [],
            maxNewPlayerLevel: 10,
          ),
          riotChampionsData: .init(data: [
            "Sett": .init(id: "Sett", key: "1", name: "Sett"),
            "Nunu": .init(id: "Nunu", key: "2", name: "Nunu & Willump"),
          ])
        )

        try await app.test(
          .GET, "/data/refresh",
          headers: ["Authorization": "Bearer 123"]
        ) { res async throws in
          #expect(res.status == .ok)
          let tokens = mocks.fcm.championReleasedMessages.map(\.token)
          #expect(tokens == ["1", "2", "3", "6"])
        }
      }
    }

    @Test func championReleasedContent() async throws {
      try await withApp { app in
        let mocks = try await app.testConfigureWith(
          appManagementKey: "123",
          dbRegularRotations: [
            .init(
              observedAt: Date.now,
              champions: ["Sett", "Senna"],
              slug: "s1w1",
            )
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Sett", name: "Sett")
          ], dbPatchVersions: [.init(value: "1")],
          dbNotificationsConfigs: [
            .init(
              userId: "1", token: "1",
              rotationChanged: true, championsAvailable: false, championReleased: true,
            )
          ],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          riotPatchVersions: ["1"],
          riotChampionRotationsData: .init(
            freeChampionIds: [1, 2],
            freeChampionIdsForNewPlayers: [],
            maxNewPlayerLevel: 10,
          ),
          riotChampionsData: .init(data: [
            "Sett": .init(id: "Sett", key: "1", name: "Sett"),
            "Nunu": .init(id: "Nunu", key: "2", name: "Nunu & Willump"),
          ])
        )

        try await app.test(
          .GET, "/data/refresh",
          headers: ["Authorization": "Bearer 123"]
        ) { res async throws in
          #expect(res.status == .ok)
          #expect(mocks.fcm.championReleasedMessages.count == 1)
          let notification = mocks.fcm.championReleasedMessages[0].notification!
          #expect(notification.title == "Champion released")
          #expect(notification.body == "Nunu & Willump is now available in the champion pool")
        }
      }
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

  var championReleasedMessages: [FCMMessageDefault] {
    sentMessages.filter { $0.data == championReleasedData }
  }
}
