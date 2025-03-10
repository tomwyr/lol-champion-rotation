import XCTVapor

@testable import App

class PredictRotationTests: AppTests {
  func testDeterministicPrediction() async throws {
    _ = try await testConfigureWith(
      idHasherSeed: idHasherSeed,
      dbRegularRotations: [
        .init(
          id: uuid("1"),
          observedAt: .iso("2024-11-10T12:00:00Z")!,
          champions: [
            "Akshan", "Chogath", "Ekko", "Evelynn", "Fizz", "Gangplank", "Gwen", "Heimerdinger",
            "Irelia", "Janna",
          ]
        ),
        .init(
          id: uuid("2"),
          observedAt: .iso("2024-11-11T12:00:00Z")!,
          champions: [
            "Aatrox", "Azir", "Bard", "Belveth", "Ekko", "Fiddlesticks", "Fizz", "Gangplank",
            "Gwen", "Jayce",
          ]
        ),
        .init(
          id: uuid("3"),
          observedAt: .iso("2024-11-12T12:00:00Z")!,
          champions: [
            "Azir", "Bard", "Braum", "Chogath", "Evelynn", "Fizz", "Gangplank", "Gnar", "Ivern",
            "Jayce",
          ]
        ),
        .init(
          id: uuid("4"),
          observedAt: .iso("2024-11-13T12:00:00Z")!,
          champions: [
            "Akshan", "Azir", "Belveth", "Braum", "Chogath", "Draven", "Evelynn", "Fizz",
            "Gangplank", "Gnar", "Irelia", "Jayce",
          ]
        ),
        .init(
          id: uuid("5"),
          observedAt: .iso("2024-11-14T12:00:00Z")!,
          champions: [
            "Aatrox", "Akshan", "Bard", "Braum", "Draven", "Evelynn", "Fizz", "Gnar", "Gwen",
            "Irelia", "Janna", "Jayce",
          ]
        ),
      ],
      dbChampions: [
        .init(id: uuid("1"), riotId: "Aatrox", name: "Aatrox"),
        .init(id: uuid("2"), riotId: "Akshan", name: "Akshan"),
        .init(id: uuid("3"), riotId: "Azir", name: "Azir"),
        .init(id: uuid("4"), riotId: "Bard", name: "Bard"),
        .init(id: uuid("5"), riotId: "Belveth", name: "Bel'Veth"),
        .init(id: uuid("6"), riotId: "Braum", name: "Braum"),
        .init(id: uuid("7"), riotId: "Chogath", name: "Cho'Gath"),
        .init(id: uuid("8"), riotId: "Draven", name: "Draven"),
        .init(id: uuid("9"), riotId: "Ekko", name: "Ekko"),
        .init(id: uuid("10"), riotId: "Evelynn", name: "Evelynn"),
        .init(id: uuid("11"), riotId: "Fiddlesticks", name: "Fiddlesticks"),
        .init(id: uuid("12"), riotId: "Fizz", name: "Fizz"),
        .init(id: uuid("13"), riotId: "Gangplank", name: "Gangplank"),
        .init(id: uuid("14"), riotId: "Gnar", name: "Gnar"),
        .init(id: uuid("15"), riotId: "Gwen", name: "Gwen"),
        .init(id: uuid("16"), riotId: "Heimerdinger", name: "Heimerdinger"),
        .init(id: uuid("17"), riotId: "Irelia", name: "Irelia"),
        .init(id: uuid("18"), riotId: "Ivern", name: "Ivern"),
        .init(id: uuid("19"), riotId: "Janna", name: "Janna"),
        .init(id: uuid("20"), riotId: "Jayce", name: "Jayce"),
      ],
      dbPatchVersions: [
        .init(
          observedAt: .iso("2024-11-01T12:00:00Z"),
          value: "15.0.1"
        )
      ],
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/rotations/predict"
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "duration": [
            "start": "2024-11-14T12:00:00Z",
            "end": "2024-11-21T12:00:00Z",
          ],
          "champions": [
            [
              "id": "00000000-0000-0000-0000-000000000002",
              "imageUrl":
                "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Akshan.jpg",
              "name": "Akshan",
            ],
            [
              "id": "00000000-0000-0000-0000-000000000003",
              "imageUrl":
                "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Azir.jpg",
              "name": "Azir",
            ],
            [
              "id": "00000000-0000-0000-0000-000000000004",
              "imageUrl":
                "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Bard.jpg",
              "name": "Bard",
            ],
            [
              "id": "00000000-0000-0000-0000-000000000007",
              "imageUrl":
                "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Chogath.jpg",
              "name": "Cho'Gath",
            ],
            [
              "id": "00000000-0000-0000-0000-000000000008",
              "imageUrl":
                "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Draven.jpg",
              "name": "Draven",
            ],
            [
              "id": "00000000-0000-0000-0000-000000000011",
              "imageUrl":
                "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Fiddlesticks.jpg",
              "name": "Fiddlesticks",
            ],
            [
              "id": "00000000-0000-0000-0000-000000000012",
              "imageUrl":
                "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Fizz.jpg",
              "name": "Fizz",
            ],
            [
              "id": "00000000-0000-0000-0000-000000000013",
              "imageUrl":
                "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Gangplank.jpg",
              "name": "Gangplank",
            ],
            [
              "id": "00000000-0000-0000-0000-000000000017",
              "imageUrl":
                "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Irelia.jpg",
              "name": "Irelia",
            ],
            [
              "id": "00000000-0000-0000-0000-000000000018",
              "imageUrl":
                "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Ivern.jpg",
              "name": "Ivern",
            ],
            [
              "id": "00000000-0000-0000-0000-000000000019",
              "imageUrl":
                "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/Janna.jpg",
              "name": "Janna",
            ],
            [
              "id": "00000000-0000-0000-0000-000000000020",
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
