import XCTVapor

@testable import App

class CurrentRotationTests: AppTests {
  let sessionKey = "4d99934d-da51-4d89-a049-b70a75b52e55"
  let userAgent =
    "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_1_2; en-US) Gecko/20100101 Firefox/72.5"

  lazy var validHeaders = {
    [
      ("X-Session-Key", sessionKey),
      ("User-Agent", userAgent),
    ]
  }()

  func testIncompleteFingerprint() async throws {
    let invalidHeaders = [
      [],
      [("X-Session-Key", sessionKey)],
      [("User-Agent", userAgent)],
      [("X-Session-Key", "123"), ("User-Agent", userAgent)],
    ]

    try await testConfigureWith()

    for headers in invalidHeaders {
      try await app.test(
        .GET, "/rotation/current",
        headers: HTTPHeaders(headers)
      ) { res async in
        XCTAssertEqual(res.status, .badRequest)
        XCTAssertBodyError(res.body, "Invalid or insufficient client information")
      }
    }
  }

  func testValidFingerprint() async throws {
    try await testConfigureWith(
      dbChampionRotation: { model in
        model.beginnerMaxLevel = 1
        model.beginnerChampions = []
        model.regularChampions = []
      }
    )

    try await app.test(
      .GET, "/rotation/current",
      headers: HTTPHeaders(validHeaders)
    ) { res async in
      XCTAssertEqual(res.status, .ok)
    }
  }

  func testResult() async throws {
    let imageUrl = { (championId: String) in
      "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/\(championId).jpg?Authorization=123"
    }

    try await testConfigureWith(
      dbChampionRotation: { model in
        model.beginnerMaxLevel = 10
        model.beginnerChampions = [.init(id: "Nocturne", name: "Nocturne")]
        model.regularChampions = [
          .init(id: "Garen", name: "Garen"),
          .init(id: "Sett", name: "Sett"),
        ]
      },
      b2AuthorizeDownloadData: .init(authorizationToken: "123")
    )

    try await app.test(
      .GET, "/rotation/current",
      headers: HTTPHeaders(validHeaders)
    ) { res async in
      XCTAssertEqual(res.status, .ok)
      XCTAssertBody(
        res.body,
        [
          "beginnerMaxLevel": 10,
          "beginnerChampions": [
            ["id": "Nocturne", "name": "Nocturne", "imageUrl": imageUrl("Nocturne")]
          ],
          "regularChampions": [
            ["id": "Garen", "name": "Garen", "imageUrl": imageUrl("Garen")],
            ["id": "Sett", "name": "Sett", "imageUrl": imageUrl("Sett")],
          ],
        ]
      )
    }
  }
}
