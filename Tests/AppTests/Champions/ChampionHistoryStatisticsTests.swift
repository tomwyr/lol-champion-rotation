import Foundation
import Testing

@testable import App

extension AppTests {
  @Suite struct ChampionHistoryStatisticsTests {
    private let statistics = ChampionHistoryStatistics()

    @Test func allStatistics() throws {
      let champions = [
        champion("Nocturne"),
        champion("Garen"),
        champion("Sett"),
        champion("Aurora", releasedAt: date(day: 3)),
      ]
      let rotations = [
        rotation(day: 5, champions: ["Nocturne", "Garen", "Sett"]),
        rotation(day: 4, champions: ["Nocturne", "Sett"]),
        rotation(day: 3, champions: ["Garen", "Sett"]),
        rotation(day: 2, champions: ["Nocturne", "Sett"]),
        rotation(day: 1, champions: ["Nocturne", "Garen"]),
      ]

      let statistics = try calculateStatistics(champions: champions, rotations: rotations)

      let nocturne = try #require(statistics["Nocturne"])
      #expect(nocturne.occurrences == 4)
      #expect(nocturne.popularity == 1)
      #expect(nocturne.currentStreak == 2)

      let sett = try #require(statistics["Sett"])
      #expect(sett.occurrences == 4)
      #expect(sett.popularity == 1)
      #expect(sett.currentStreak == 4)

      let garen = try #require(statistics["Garen"])
      #expect(garen.occurrences == 3)
      #expect(garen.popularity == 3)
      #expect(garen.currentStreak == 1)

      let aurora = try #require(statistics["Aurora"])
      #expect(aurora.occurrences == 0)
      #expect(aurora.popularity == 4)
      #expect(aurora.currentStreak == -3)
    }

    @Test func emptyChampionList() throws {
      let rotations = [
        rotation(day: 1, champions: ["Garen"])
      ]

      let statistics = try statistics.calculate(champions: [], rotations: rotations)

      #expect(statistics.isEmpty)
    }

    @Test func recencyTie() throws {
      let champions = [
        champion("Nocturne"),
        champion("Garen"),
      ]
      let rotations = [
        rotation(day: 14, champions: ["Nocturne"]),
        rotation(day: 13, champions: []),
        rotation(day: 12, champions: []),
        rotation(day: 11, champions: []),
        rotation(day: 10, champions: []),
        rotation(day: 9, champions: []),
        rotation(day: 8, champions: []),
        rotation(day: 7, champions: []),
        rotation(day: 6, champions: []),
        rotation(day: 5, champions: []),
        rotation(day: 4, champions: []),
        rotation(day: 3, champions: []),
        rotation(day: 2, champions: []),
        rotation(day: 1, champions: ["Garen"]),
      ]

      let statistics = try calculateStatistics(champions: champions, rotations: rotations)

      let nocturne = try #require(statistics["Nocturne"])
      let garen = try #require(statistics["Garen"])

      #expect(nocturne.popularity == 1)
      #expect(garen.popularity == 1)
    }

    @Test func currentStreak() throws {
      let champions = [
        champion("Garen"),
        champion("Nocturne"),
      ]
      let rotations = [
        rotation(day: 11, champions: ["Garen", "Nocturne"]),
        rotation(day: 14, champions: ["Garen"]),
        rotation(day: 12, champions: ["Garen"]),
        rotation(day: 13, champions: ["Garen"]),
      ]

      let statistics = try calculateStatistics(champions: champions, rotations: rotations)

      let garen = try #require(statistics["Garen"])
      let nocturne = try #require(statistics["Nocturne"])

      #expect(garen.currentStreak == 4)
      #expect(nocturne.currentStreak == -3)
    }

    @Test func distinctPopularity() throws {
      let champions = [
        champion("Aurora", releasedAt: date(day: 14)),
        champion("Sett"),
        champion("Nocturne"),
      ]
      let rotations = [
        rotation(day: 14, champions: ["Aurora", "Nocturne"]),
        rotation(day: 13, champions: ["Nocturne", "Sett"]),
        rotation(day: 12, champions: ["Nocturne"]),
        rotation(day: 11, champions: ["Nocturne", "Sett"]),
        rotation(day: 10, champions: ["Nocturne"]),
        rotation(day: 9, champions: ["Nocturne", "Sett"]),
        rotation(day: 8, champions: ["Nocturne"]),
        rotation(day: 7, champions: ["Nocturne", "Sett"]),
        rotation(day: 6, champions: ["Nocturne"]),
        rotation(day: 5, champions: ["Nocturne", "Sett"]),
        rotation(day: 4, champions: ["Nocturne"]),
        rotation(day: 3, champions: ["Nocturne", "Sett"]),
        rotation(day: 2, champions: ["Nocturne"]),
        rotation(day: 1, champions: ["Nocturne", "Sett"]),
      ]

      let statistics = try calculateStatistics(champions: champions, rotations: rotations)

      let nocturne = try #require(statistics["Nocturne"])
      let sett = try #require(statistics["Sett"])
      let aurora = try #require(statistics["Aurora"])

      #expect(nocturne.popularity == 1)
      #expect(sett.popularity == 2)
      #expect(aurora.popularity == 3)
    }

    @Test func popularityWithoutAppearances() throws {
      let champions = [
        champion("Aurora", releasedAt: date(day: 14)),
        champion("Garen"),
        champion("Nocturne"),
      ]
      let rotations = [
        rotation(day: 14, champions: ["Nocturne"]),
        rotation(day: 13, champions: ["Nocturne"]),
        rotation(day: 12, champions: ["Nocturne"]),
        rotation(day: 11, champions: ["Nocturne"]),
        rotation(day: 10, champions: ["Nocturne"]),
        rotation(day: 9, champions: ["Nocturne"]),
        rotation(day: 8, champions: ["Nocturne"]),
        rotation(day: 7, champions: ["Nocturne"]),
        rotation(day: 6, champions: ["Nocturne"]),
        rotation(day: 5, champions: ["Nocturne"]),
        rotation(day: 4, champions: ["Nocturne"]),
        rotation(day: 3, champions: ["Nocturne"]),
        rotation(day: 2, champions: ["Nocturne"]),
        rotation(day: 1, champions: ["Nocturne"]),
      ]

      let statistics = try calculateStatistics(champions: champions, rotations: rotations)

      let aurora = try #require(statistics["Aurora"])
      let garen = try #require(statistics["Garen"])

      #expect(aurora.popularity == 2)
      #expect(garen.popularity == 2)
    }

    @Test func newChampionsPopularity() throws {
      let champions = [
        champion("Aurora", releasedAt: date(day: 14)),
        champion("Garen"),
      ]
      let rotations = [
        rotation(day: 14, champions: ["Aurora", "Garen"]),
        rotation(day: 13, champions: []),
        rotation(day: 12, champions: []),
        rotation(day: 11, champions: []),
        rotation(day: 10, champions: []),
        rotation(day: 9, champions: []),
        rotation(day: 8, champions: []),
        rotation(day: 7, champions: []),
        rotation(day: 6, champions: []),
        rotation(day: 5, champions: []),
        rotation(day: 4, champions: []),
        rotation(day: 3, champions: []),
        rotation(day: 2, champions: []),
        rotation(day: 1, champions: []),
      ]

      let statistics = try calculateStatistics(champions: champions, rotations: rotations)

      let aurora = try #require(statistics["Aurora"])
      let garen = try #require(statistics["Garen"])

      #expect(aurora.popularity == 1)
      #expect(garen.popularity == 1)
    }

    @Test func equalOccurrencesPopularity() throws {
      let champions = [
        champion("Nocturne"),
        champion("Sett"),
        champion("Garen"),
        champion("Senna"),
      ]
      let rotations = [
        rotation(day: 14, champions: ["Nocturne", "Sett", "Garen"]),
        rotation(day: 13, champions: ["Nocturne"]),
        rotation(day: 12, champions: ["Nocturne", "Sett", "Garen"]),
        rotation(day: 11, champions: ["Nocturne"]),
        rotation(day: 10, champions: ["Nocturne", "Sett", "Garen"]),
        rotation(day: 9, champions: ["Nocturne"]),
        rotation(day: 8, champions: ["Nocturne", "Sett", "Garen"]),
        rotation(day: 7, champions: ["Nocturne"]),
        rotation(day: 6, champions: ["Nocturne", "Sett", "Garen"]),
        rotation(day: 5, champions: ["Nocturne"]),
        rotation(day: 4, champions: ["Nocturne", "Sett", "Garen"]),
        rotation(day: 3, champions: ["Nocturne"]),
        rotation(day: 2, champions: ["Nocturne", "Sett", "Garen"]),
        rotation(day: 1, champions: ["Nocturne"]),
      ]

      let statistics = try calculateStatistics(champions: champions, rotations: rotations)

      let sett = try #require(statistics["Sett"])
      let garen = try #require(statistics["Garen"])
      let senna = try #require(statistics["Senna"])

      #expect(sett.popularity == 2)
      #expect(garen.popularity == 2)
      #expect(senna.popularity == 4)
    }

    @Test func missingReleaseDate() {
      let unknown = champion("Unknown", releasedAt: nil)

      #expect(throws: ChampionHistoryStatisticsError.insufficientData(championId: "Unknown")) {
        try statistics.calculate(champions: [unknown], rotations: [])
      }
    }

    @Test func currentPresentStreak() throws {
      let champions = [
        champion("Garen"),
        champion("Nocturne"),
      ]
      let rotations = [
        rotation(day: 14, champions: ["Garen", "Nocturne"]),
        rotation(day: 13, champions: ["Garen"]),
        rotation(day: 12, champions: ["Garen"]),
        rotation(day: 11, champions: ["Nocturne"]),
      ]

      let statistics = try calculateStatistics(champions: champions, rotations: rotations)

      let garen = try #require(statistics["Garen"])
      let nocturne = try #require(statistics["Nocturne"])

      #expect(garen.currentStreak == 3)
      #expect(nocturne.currentStreak == 1)
    }

    @Test func currentAbsentStreak() throws {
      let champions = [
        champion("Sett"),
        champion("Senna", releasedAt: date(day: 13)),
        champion("Garen"),
      ]
      let rotations = [
        rotation(day: 14, champions: ["Garen"]),
        rotation(day: 13, champions: ["Garen"]),
        rotation(day: 12, champions: ["Sett", "Garen"]),
        rotation(day: 11, champions: ["Senna", "Garen"]),
      ]

      let statistics = try calculateStatistics(champions: champions, rotations: rotations)

      let sett = try #require(statistics["Sett"])
      let senna = try #require(statistics["Senna"])

      #expect(sett.currentStreak == -2)
      #expect(senna.currentStreak == -2)
    }

    private func calculateStatistics(
      champions: [ChampionModel],
      rotations: [RegularChampionRotationModel],
    ) throws -> [String: ChampionHistoryStatisticsModel] {
      try statistics.calculate(champions: champions, rotations: rotations)
        .associatedBy(key: \.championRiotId)
    }
  }
}

private func champion(_ id: String, releasedAt: Date? = date(day: 1)) -> ChampionModel {
  .init(
    releasedAt: releasedAt,
    riotId: id,
    name: id,
    title: "",
  )
}

private func rotation(day: Int, champions: [String]) -> RegularChampionRotationModel {
  .init(
    observedAt: date(day: day),
    champions: champions,
    slug: "rotation-\(day)"
  )
}

private func rotation(age: Int, champions: [String]) -> RegularChampionRotationModel {
  .init(
    observedAt: date(age: age),
    champions: champions,
    slug: "rotation-\(age)"
  )
}

private func date(day: Int) -> Date {
  let paddedDay = String(format: "%02d", day)
  return .iso("2024-01-\(paddedDay)T00:00:00Z")!
}

private func date(age: Int) -> Date {
  let startDate = Date.iso("2024-01-01T00:00:00Z")!
  return startDate.subtracting(age, .day)!
}
