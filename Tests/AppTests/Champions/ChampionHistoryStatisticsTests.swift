import Foundation
import Testing

@testable import App

extension AppTests {
  @Suite struct ChampionHistoryStatisticsTests {
    private let statistics = ChampionHistoryStatistics()

    @Test func recencyDoesNotBreakTies() throws {
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

      let popularity = try popularity(champions: champions, rotations: rotations)

      #expect(popularity[champions[0].riotId] == 1)
      #expect(popularity[champions[1].riotId] == 1)
    }

    @Test func fewerAppearancesRankLower() throws {
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

      let popularity = try popularity(champions: champions, rotations: rotations)

      #expect(popularity[champions[2].riotId] == 1)
      #expect(popularity[champions[1].riotId] == 2)
      #expect(popularity[champions[0].riotId] == 3)
    }

    @Test func championsWithoutAppearancesShareRank() throws {
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

      let popularity = try popularity(champions: champions, rotations: rotations)

      #expect(popularity[champions[0].riotId] == 2)
      #expect(popularity[champions[1].riotId] == 2)
    }

    @Test func newChampionNotBoosted() throws {
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

      let popularity = try popularity(champions: champions, rotations: rotations)

      #expect(popularity[champions[0].riotId] == 1)
      #expect(popularity[champions[1].riotId] == 1)
    }

    @Test func equalCountsShareRank() throws {
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

      let popularity = try popularity(champions: champions, rotations: rotations)

      #expect(popularity[champions[1].riotId] == 2)
      #expect(popularity[champions[2].riotId] == 2)
      #expect(popularity[champions[3].riotId] == 4)
    }

    @Test func missingReleaseDateFails() {
      let unknown = champion("Unknown", releasedAt: nil)

      #expect(throws: ChampionHistoryStatisticsError.insufficientData(championRiotId: "Unknown")) {
        try statistics.calculate(champions: [unknown], rotations: [])
      }
    }

    @Test func preReleaseRotationsIgnored() throws {
      let champions = [
        champion("Aurora", releasedAt: date(day: 10)),
        champion("Nocturne"),
      ]
      let rotations = [
        rotation(day: 14, champions: ["Aurora", "Nocturne"]),
        rotation(day: 13, champions: ["Nocturne"]),
        rotation(day: 12, champions: ["Nocturne"]),
        rotation(day: 11, champions: ["Nocturne"]),
        rotation(day: 10, champions: ["Nocturne"]),
        rotation(day: 9, champions: ["Aurora"]),
        rotation(day: 8, champions: ["Aurora"]),
        rotation(day: 7, champions: ["Aurora"]),
        rotation(day: 6, champions: ["Aurora"]),
        rotation(day: 5, champions: ["Aurora"]),
        rotation(day: 4, champions: ["Aurora"]),
        rotation(day: 3, champions: ["Aurora"]),
        rotation(day: 2, champions: ["Aurora"]),
        rotation(day: 1, champions: ["Aurora"]),
      ]

      let popularity = try popularity(champions: champions, rotations: rotations)

      #expect(popularity[champions[0].riotId] == 2)
    }

    private func popularity(
      champions: [ChampionModel],
      rotations: [RegularChampionRotationModel],
    ) throws -> [String: Int] {
      let statistics = try statistics.calculate(champions: champions, rotations: rotations)
      return statistics.reduce(into: [:]) { result, statistics in
        result[statistics.championRiotId] = statistics.popularity
      }
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
