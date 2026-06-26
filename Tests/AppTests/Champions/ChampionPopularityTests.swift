import Foundation
import Testing

@testable import App

extension AppTests {
  @Suite struct ChampionPopularityTests {
    private let calculator = ChampionPopularity()

    @Test func recentAppearancesRankHigher() throws {
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

      let popularity = { (champion: ChampionModel) throws -> Int in
        try calculator.calculate(for: champion, champions: champions, rotations: rotations)
      }

      #expect(try popularity(champions[0]) == 1)
      #expect(try popularity(champions[1]) == 2)
    }

    @Test func newChampionRanksBelowRepeatedAppearances() throws {
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

      let popularity = { (champion: ChampionModel) throws -> Int in
        try calculator.calculate(for: champion, champions: champions, rotations: rotations)
      }

      #expect(try popularity(champions[2]) == 1)
      #expect(try popularity(champions[1]) == 2)
      #expect(try popularity(champions[0]) == 3)
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

      let popularity = { (champion: ChampionModel) throws -> Int in
        try calculator.calculate(for: champion, champions: champions, rotations: rotations)
      }

      #expect(try popularity(champions[0]) == 2)
      #expect(try popularity(champions[1]) == 2)
    }

    @Test func newChampionReceivesBoost() throws {
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

      let popularity = { (champion: ChampionModel) throws -> Int in
        try calculator.calculate(for: champion, champions: champions, rotations: rotations)
      }

      #expect(try popularity(champions[0]) == 1)
      #expect(try popularity(champions[1]) == 2)
    }

    @Test func equalScoresShareRank() throws {
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

      let popularity = { (champion: ChampionModel) throws -> Int in
        try calculator.calculate(for: champion, champions: champions, rotations: rotations)
      }

      #expect(try popularity(champions[1]) == 2)
      #expect(try popularity(champions[2]) == 2)
      #expect(try popularity(champions[3]) == 4)
    }

    @Test func missingReleaseDateFails() {
      let unknown = champion("Unknown")

      #expect(throws: ChampionPopularityError.insufficientData) {
        try calculator.calculate(for: unknown, champions: [unknown], rotations: [])
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

      let popularity = { (champion: ChampionModel) throws -> Int in
        try calculator.calculate(for: champion, champions: champions, rotations: rotations)
      }

      #expect(try popularity(champions[0]) == 2)
    }

    @Test func oldRotationsIgnored() throws {
      let champions = [
        champion("Nocturne"),
        champion("Garen"),
      ]
      let rotationsLimit = 104
      let rotations =
        [rotation(age: 0, champions: ["Nocturne"])]
        + (1..<rotationsLimit).map { age in rotation(age: age, champions: []) }
        + [rotation(age: rotationsLimit, champions: ["Garen"])]

      let popularity = { (champion: ChampionModel) throws -> Int in
        try calculator.calculate(for: champion, champions: champions, rotations: rotations)
      }

      #expect(try popularity(champions[0]) == 1)
      #expect(try popularity(champions[1]) == 2)
    }
  }
}

private func champion(_ id: String, releasedAt: Date = date(day: 1)) -> ChampionModel {
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
    observedAt: date(day: 14 - age),
    champions: champions,
    slug: "rotation-\(age)"
  )
}

private func date(day: Int) -> Date {
  let paddedDay = String(format: "%02d", day)
  return .iso("2024-01-\(paddedDay)T00:00:00Z")!
}
