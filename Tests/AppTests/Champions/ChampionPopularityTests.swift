import Foundation
import Testing

@testable import App

extension AppTests {
  @Suite struct ChampionPopularityTests {
    private let calculator = ChampionPopularity()

    @Test func recentAppearancesRankHigher() throws {
      let champions = [
        champion("Recent"),
        champion("Historical"),
      ]
      let rotations = (0...13).map { age in
        rotation(
          age: age,
          champions: age == 0 ? ["Recent"] : age == 13 ? ["Historical"] : []
        )
      }

      let popularity = { (champion: ChampionModel) throws -> Int in
        try calculator.calculate(for: champion, champions: champions, rotations: rotations)
      }

      #expect(try popularity(champions[0]) == 1)
      #expect(try popularity(champions[1]) == 2)
    }

    @Test func newChampionRanksBelowRepeatedAppearances() throws {
      let champions = [
        champion("New", releasedAt: date(day: 14)),
        champion("Regular"),
        champion("Frequent"),
      ]
      let rotations = (0..<14).map { age in
        rotation(
          age: age,
          champions: age == 0
            ? ["New", "Frequent"]
            : age.isMultiple(of: 2) ? ["Frequent"] : ["Frequent", "Regular"]
        )
      }

      let popularity = { (champion: ChampionModel) throws -> Int in
        try calculator.calculate(for: champion, champions: champions, rotations: rotations)
      }

      #expect(try popularity(champions[2]) == 1)
      #expect(try popularity(champions[1]) == 2)
      #expect(try popularity(champions[0]) == 3)
    }

    @Test func championsWithoutAppearancesShareRank() throws {
      let champions = [
        champion("New", releasedAt: date(day: 14)),
        champion("Never"),
        champion("Frequent"),
      ]
      let rotations = (0..<14).map { age in
        rotation(age: age, champions: ["Frequent"])
      }

      let popularity = { (champion: ChampionModel) throws -> Int in
        try calculator.calculate(for: champion, champions: champions, rotations: rotations)
      }

      #expect(try popularity(champions[0]) == 2)
      #expect(try popularity(champions[1]) == 2)
    }

    @Test func newChampionReceivesBoost() throws {
      let champions = [
        champion("New", releasedAt: date(day: 14)),
        champion("Established"),
      ]
      let rotations = (0..<14).map { age in
        rotation(age: age, champions: age == 0 ? ["New", "Established"] : [])
      }

      let popularity = { (champion: ChampionModel) throws -> Int in
        try calculator.calculate(for: champion, champions: champions, rotations: rotations)
      }

      #expect(try popularity(champions[0]) == 1)
      #expect(try popularity(champions[1]) == 2)
    }

    @Test func equalScoresShareRank() throws {
      let champions = [
        champion("Leader"),
        champion("One"),
        champion("Two"),
        champion("Never"),
      ]
      let rotations = (0..<14).map { age in
        rotation(
          age: age,
          champions: age.isMultiple(of: 2) ? ["Leader", "One", "Two"] : ["Leader"]
        )
      }

      let popularity = { (champion: ChampionModel) throws -> Int in
        try calculator.calculate(for: champion, champions: champions, rotations: rotations)
      }

      #expect(try popularity(champions[1]) == 2)
      #expect(try popularity(champions[2]) == 2)
      #expect(try popularity(champions[3]) == 4)
    }

    @Test func missingReleaseDateFails() {
      let unknown = ChampionModel(
        riotId: "Unknown", name: "Unknown", title: "the Unknown"
      )

      #expect(throws: ChampionPopularityError.insufficientData) {
        try calculator.calculate(for: unknown, champions: [unknown], rotations: [])
      }
    }

    @Test func preReleaseRotationsIgnored() throws {
      let champions = [
        champion("New", releasedAt: date(day: 10)),
        champion("Frequent"),
      ]
      let rotations = (0..<14).map { age in
        rotation(
          age: age,
          champions: age == 0 ? ["New", "Frequent"] : age < 5 ? ["Frequent"] : ["New"]
        )
      }

      let popularity = { (champion: ChampionModel) throws -> Int in
        try calculator.calculate(for: champion, champions: champions, rotations: rotations)
      }

      #expect(try popularity(champions[0]) == 2)
    }

    @Test func oldRotationsIgnored() throws {
      let champions = [
        champion("Recent"),
        champion("TooOld"),
      ]
      let rotationsLimit = 104
      let rotations = (0...rotationsLimit).map { age in
        RegularChampionRotationModel(
          observedAt: date(day: 14),
          champions: age == 0 ? ["Recent"] : age == rotationsLimit ? ["TooOld"] : [],
          slug: "rotation-\(age)"
        )
      }

      let popularity = { (champion: ChampionModel) throws -> Int in
        try calculator.calculate(for: champion, champions: champions, rotations: rotations)
      }

      #expect(try popularity(champions[0]) == 1)
      #expect(try popularity(champions[1]) == 2)
    }
  }
}

private func champion(_ id: String, releasedAt: Date = date(day: 1)) -> ChampionModel {
  .init(releasedAt: releasedAt, riotId: id, name: id, title: "the \(id)")
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
