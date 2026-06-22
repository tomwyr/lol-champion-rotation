import Foundation
import Testing

@testable import App

extension AppTests {
  @Suite(.serialized) struct CurrentRotationPredictionTests {
    @Test(.serialized, arguments: appAccessTokens)
    func currentPrediction(accessToken: String) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("5"),
              observedAt: .iso("2024-11-14T12:00:00Z")!,
              champions: [],
              slug: "s1w5",
            )
          ],
          dbRotationPredictions: [
            .init(
              refRotationId: uuid("5")!,
              champions: [
                "Akshan", "Azir", "Bard", "Chogath", "Draven", "Fiddlesticks", "Fizz", "Gangplank",
                "Irelia", "Ivern", "Janna", "Jayce",
              ],
            )
          ],
          dbChampions: [
            .init(id: uuid("1"), riotId: "Akshan", name: "Akshan"),
            .init(id: uuid("2"), riotId: "Azir", name: "Azir"),
            .init(id: uuid("3"), riotId: "Bard", name: "Bard"),
            .init(id: uuid("4"), riotId: "Chogath", name: "Cho'Gath"),
            .init(id: uuid("5"), riotId: "Draven", name: "Draven"),
            .init(id: uuid("6"), riotId: "Fiddlesticks", name: "Fiddlesticks"),
            .init(id: uuid("7"), riotId: "Fizz", name: "Fizz"),
            .init(id: uuid("8"), riotId: "Gangplank", name: "Gangplank"),
            .init(id: uuid("9"), riotId: "Irelia", name: "Irelia"),
            .init(id: uuid("10"), riotId: "Ivern", name: "Ivern"),
            .init(id: uuid("11"), riotId: "Janna", name: "Janna"),
            .init(id: uuid("12"), riotId: "Jayce", name: "Jayce"),
          ],
          dbPatchVersions: [
            .init(
              observedAt: .iso("2024-11-01T12:00:00Z"),
              value: "15.0.1"
            )
          ],
          dbChampionRotationConfigs: [.init(rotationChangeWeekday: 4)],
          b2AuthorizeDownloadData: .init(authorizationToken: "123"),
        )

        try await app.test(
          .GET, "/rotations/prediction",
          headers: reqHeaders(accessToken: accessToken),
        ) { res async throws in
          #expect(res.status == .ok)
          try expectBody(
            res.body,
            [
              "duration": [
                "start": "2024-11-21T12:00:00Z",
                "end": "2024-11-28T12:00:00Z",
              ],
              "champions": [
                [
                  "id": "akshan",
                  "imageUrl":
                    "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Akshan.jpg",
                  "name": "Akshan",
                ],
                [
                  "id": "azir",
                  "imageUrl":
                    "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Azir.jpg",
                  "name": "Azir",
                ],
                [
                  "id": "bard",
                  "imageUrl":
                    "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Bard.jpg",
                  "name": "Bard",
                ],
                [
                  "id": "chogath",
                  "imageUrl":
                    "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Chogath.jpg",
                  "name": "Cho'Gath",
                ],
                [
                  "id": "draven",
                  "imageUrl":
                    "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Draven.jpg",
                  "name": "Draven",
                ],
                [
                  "id": "fiddlesticks",
                  "imageUrl":
                    "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Fiddlesticks.jpg",
                  "name": "Fiddlesticks",
                ],
                [
                  "id": "fizz",
                  "imageUrl":
                    "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Fizz.jpg",
                  "name": "Fizz",
                ],
                [
                  "id": "gangplank",
                  "imageUrl":
                    "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Gangplank.jpg",
                  "name": "Gangplank",
                ],
                [
                  "id": "irelia",
                  "imageUrl":
                    "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Irelia.jpg",
                  "name": "Irelia",
                ],
                [
                  "id": "ivern",
                  "imageUrl":
                    "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Ivern.jpg",
                  "name": "Ivern",
                ],
                [
                  "id": "janna",
                  "imageUrl":
                    "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Janna.jpg",
                  "name": "Janna",
                ],
                [
                  "id": "jayce",
                  "imageUrl":
                    "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Jayce.jpg",
                  "name": "Jayce",
                ],
              ],
            ]
          )
        }
      }
    }

    @Test(.serialized, arguments: appAccessTokens)
    func missingPrediction(accessToken: String) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbRegularRotations: [
            .init(
              id: uuid("1"),
              observedAt: .iso("2024-11-10T12:00:00Z")!,
              champions: [],
              slug: "s1w1",
            )
          ],
          b2AuthorizeDownloadData: .init(authorizationToken: "123"),
        )

        try await app.test(
          .GET, "/rotations/prediction",
          headers: reqHeaders(accessToken: accessToken),
        ) { res async throws in
          #expect(res.status == .notFound)
          let predictions = try await app.dbRotationPredictions()
          #expect(predictions.isEmpty)
        }
      }
    }

    @Test(.serialized, arguments: appAccessTokens)
    func missingCurrentRotation(accessToken: String) async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith(
          webApiKey: webApiKey,
          idHasherSeed: idHasherSeed,
          dbRotationPredictions: [
            .init(refRotationId: uuid("1")!, champions: ["Akshan"])
          ],
          b2AuthorizeDownloadData: .init(authorizationToken: "123"),
        )

        try await app.test(
          .GET, "/rotations/prediction",
          headers: reqHeaders(accessToken: accessToken),
        ) { res async throws in
          #expect(res.status == .notFound)
        }
      }
    }
  }
}
