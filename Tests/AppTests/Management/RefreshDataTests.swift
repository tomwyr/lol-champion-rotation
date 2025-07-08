import Foundation
import Testing

@testable import App

extension AppTests {
  @Suite(.serialized) struct RefreshDataTests {
    @Test func noToken() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(appManagementKey: "123")

        try await app.test(
          .GET, "/data/refresh"
        ) { res async throws in
          #expect(res.status == .unauthorized)
          try expectBodyError(res.body, "Invalid auth token")
        }
      }
    }

    @Test func invalidToken() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(appManagementKey: "abc")

        try await app.test(
          .GET, "/data/refresh",
          headers: ["Authorization": "Bearer 123"]
        ) { res async throws in
          #expect(res.status == .unauthorized)
          try expectBodyError(res.body, "Invalid auth token")
        }
      }
    }

    @Test func validToken() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appManagementKey: "123",
          dbPatchVersions: [.init(value: "1")],
          riotPatchVersions: ["1"]
        )

        try await app.test(
          .GET, "/data/refresh",
          headers: ["Authorization": "Bearer 123"]
        ) { res async throws in
          #expect(res.status == .ok)
        }
      }
    }

    @Test func rotationChampionsChanged() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appManagementKey: "123",
          dbRegularRotations: [
            .init(
              observedAt: Date.now,
              champions: ["Sett", "Senna"],
              slug: "s1w1",
            )
          ],
          dbBeginnerRotations: [
            .init(
              observedAt: Date.now,
              maxLevel: 10,
              champions: ["Nocturne"]
            )
          ],
          dbPatchVersions: [.init(value: "1")],
          riotPatchVersions: ["1"],
          riotChampionRotationsData: .init(
            freeChampionIds: [1, 2],
            freeChampionIdsForNewPlayers: [3],
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
          try expectBody(
            res.body, at: "rotation",
            [
              "rotationChanged": true,
              "championsAdded": true,
            ]
          )
        }
      }
    }

    @Test func rotationMaxLevelChanged() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appManagementKey: "123",
          dbRegularRotations: [
            .init(
              observedAt: Date.now,
              champions: ["Sett", "Garen"],
              slug: "s1w1",
            )
          ],
          dbBeginnerRotations: [
            .init(
              observedAt: Date.now,
              maxLevel: 5,
              champions: ["Nocturne"]
            )
          ],
          dbPatchVersions: [.init(value: "1")],
          riotPatchVersions: ["1"],
          riotChampionRotationsData: .init(
            freeChampionIds: [1, 2],
            freeChampionIdsForNewPlayers: [3],
            maxNewPlayerLevel: 10,
          ),
          riotChampionsData: .init(data: [
            "Sett": .init(id: "Sett", key: "1", name: "Sett"),
            "Garen": .init(id: "Garen", key: "2", name: "Garen"),
            "Nocturne": .init(id: "Nocturne", key: "3", name: "Nocturne"),
          ])
        )

        try await app.test(
          .GET, "/data/refresh",
          headers: ["Authorization": "Bearer 123"]
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body, at: "rotation",
            [
              "rotationChanged": true,
              "championsAdded": true,
            ]
          )
        }
      }
    }

    @Test func rotationDidNotChange() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appManagementKey: "123",
          dbRegularRotations: [
            .init(
              observedAt: Date.now,
              champions: ["Sett", "Garen"],
              slug: "s1w1",
            )
          ],
          dbBeginnerRotations: [
            .init(
              observedAt: Date.now,
              maxLevel: 10,
              champions: ["Nocturne"]
            )
          ],
          dbPatchVersions: [.init(value: "1")],
          riotPatchVersions: ["1"],
          riotChampionRotationsData: .init(
            freeChampionIds: [1, 2],
            freeChampionIdsForNewPlayers: [3],
            maxNewPlayerLevel: 10,
          ),
          riotChampionsData: .init(data: [
            "Sett": .init(id: "Sett", key: "1", name: "Sett"),
            "Garen": .init(id: "Garen", key: "2", name: "Garen"),
            "Nocturne": .init(id: "Nocturne", key: "3", name: "Nocturne"),
          ])
        )

        try await app.test(
          .GET, "/data/refresh",
          headers: ["Authorization": "Bearer 123"]
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body, at: "rotation",
            [
              "rotationChanged": false,
              "championsAdded": true,
            ]
          )
        }
      }
    }

    @Test func championsDidNotChange() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appManagementKey: "123",
          dbRegularRotations: [
            .init(
              observedAt: Date.now,
              champions: ["Sett", "Garen"],
              slug: "s1w1",
            )
          ],
          dbBeginnerRotations: [
            .init(
              observedAt: Date.now,
              maxLevel: 10,
              champions: ["Nocturne"]
            )
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Sett", name: "Sett"),
            .init(id: uuid("2"), riotId: "Garen", name: "Garen"),
            .init(id: uuid("3"), riotId: "Nocturne", name: "Nocturne"),
          ],
          dbPatchVersions: [.init(value: "1")],
          riotPatchVersions: ["1"],
          riotChampionRotationsData: .init(
            freeChampionIds: [1, 2],
            freeChampionIdsForNewPlayers: [3],
            maxNewPlayerLevel: 10,
          ),
          riotChampionsData: .init(data: [
            "Sett": .init(id: "Sett", key: "1", name: "Sett"),
            "Garen": .init(id: "Garen", key: "2", name: "Garen"),
            "Nocturne": .init(id: "Nocturne", key: "3", name: "Nocturne"),
          ])
        )

        try await app.test(
          .GET, "/data/refresh",
          headers: ["Authorization": "Bearer 123"]
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body, at: "rotation",
            [
              "rotationChanged": false,
              "championsAdded": false,
            ]
          )
        }
      }
    }

    @Test func multipleLocalVersions() async throws {
      try await withApp { app in
        let (httpClient, _) = try await app.testConfigureWith(
          appManagementKey: "123",
          dbPatchVersions: [
            .init(value: "15.23.5"),
            .init(value: "15.23.0"),
            .init(value: "15.22.8"),
          ],
          riotPatchVersions: ["15.23.5"]
        )

        try await app.test(
          .GET, "/data/refresh",
          headers: ["Authorization": "Bearer 123"]
        ) { res async throws in
          let latestChampionsUrl = requestUrls.riotChampions("15.23.5")
          #expect(httpClient.requestedUrls.contains(latestChampionsUrl))
        }
      }
    }

    @Test func multipleRiotVersions() async throws {
      try await withApp { app in
        let (httpClient, _) = try await app.testConfigureWith(
          appManagementKey: "123",
          dbPatchVersions: [.init(value: "1")],
          riotPatchVersions: ["15.23.5", "15.23.0", "15.22.8"]
        )

        try await app.test(
          .GET, "/data/refresh",
          headers: ["Authorization": "Bearer 123"]
        ) { res async throws in
          let latestChampionsUrl = requestUrls.riotChampions("15.23.5")
          #expect(httpClient.requestedUrls.contains(latestChampionsUrl))
        }
      }
    }

    @Test func differentVersions() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appManagementKey: "123",
          dbPatchVersions: [.init(value: "14.0.0")],
          riotPatchVersions: ["15.23.5"]
        )

        try await app.test(
          .GET, "/data/refresh",
          headers: ["Authorization": "Bearer 123"]
        ) { res async throws in
          let versions = try await app.dbPatchVersions()
          #expect(versions == ["14.0.0", "15.23.5"])
          #expect(res.status == .ok)
          try expectBody(
            res.body, at: "version",
            ["latestVersion": "15.23.5", "versionChanged": true]
          )
        }
      }
    }

    @Test func identicalVersions() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appManagementKey: "123",
          dbPatchVersions: [.init(value: "15.23.5")],
          riotPatchVersions: ["15.23.5"]
        )

        try await app.test(
          .GET, "/data/refresh",
          headers: ["Authorization": "Bearer 123"]
        ) { res async throws in
          let versions = try await app.dbPatchVersions()
          #expect(versions == ["15.23.5"])
          #expect(res.status == .ok)
          try expectBody(
            res.body, at: "version",
            ["latestVersion": "15.23.5", "versionChanged": false]
          )
        }
      }
    }

    @Test func noLocalVersion() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appManagementKey: "123",
          dbPatchVersions: [],
          riotPatchVersions: ["15.23.5"]
        )

        try await app.test(
          .GET, "/data/refresh",
          headers: ["Authorization": "Bearer 123"],
        ) { res async throws in
          let versions = try await app.dbPatchVersions()
          #expect(versions == ["15.23.5"])
          #expect(res.status == .ok)
          try expectBody(
            res.body, at: "version",
            ["latestVersion": "15.23.5", "versionChanged": true]
          )
        }
      }
    }

    @Test func newChampionSaved() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appManagementKey: "123",
          riotPatchVersions: ["15.1.1"],
          riotChampionRotationsData: .init(
            freeChampionIds: [1],
            freeChampionIdsForNewPlayers: [],
            maxNewPlayerLevel: 10,
          ),
          riotChampionsData: .init(data: [
            "Sett": .init(id: "Nunu", key: "1", name: "Nunu & Willump")
          ]),
        )

        try await app.test(
          .GET, "/data/refresh",
          headers: ["Authorization": "Bearer 123"],
        ) { res async throws in
          let champions = try await app.dbChampions()
          #expect(champions.count == 1)
          #expect(champions[0].name == "Nunu & Willump")
          #expect(champions[0].riotId == "Nunu")
        }
      }
    }

    @Test func newRotationSaved() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          appManagementKey: "123",
          riotPatchVersions: ["15.1.1"],
          riotChampionRotationsData: .init(
            freeChampionIds: [1],
            freeChampionIdsForNewPlayers: [],
            maxNewPlayerLevel: 10,
          ),
          riotChampionsData: .init(data: [
            "Sett": .init(id: "Sett", key: "1", name: "Sett")
          ]),
        )

        try await app.test(
          .GET, "/data/refresh",
          headers: ["Authorization": "Bearer 123"],
        ) { res async throws in
          let rotations = try await app.dbRegularRotations()
          #expect(rotations.count == 1)
          #expect(rotations[0].champions == ["Sett"])
          #expect(rotations[0].slug == "s15w1")
        }
      }
    }
  }
}
