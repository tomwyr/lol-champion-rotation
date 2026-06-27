import Foundation

struct ChampionHistoryStatistics {
  func calculate(
    champions: [ChampionModel],
    rotations: [RegularChampionRotationModel],
  ) throws -> [ChampionHistoryStatisticsModel] {
    let occurrences = occurrencesByChampion(champions, rotations)
    let data = StatisticsData(
      occurrences: occurrences,
      popularity: popularityByChampion(occurrences),
      currentStreaks: try currentStreaksByChampion(champions, rotations),
    )

    return try champions.map { champion in
      let championId = champion.riotId
      return ChampionHistoryStatisticsModel(
        championRiotId: championId,
        occurrences: try data.result(for: championId, \.occurrences),
        popularity: try data.result(for: championId, \.popularity),
        currentStreak: try data.result(for: championId, \.currentStreaks),
      )
    }
  }

  private func occurrencesByChampion(
    _ champions: [ChampionModel],
    _ rotations: [RegularChampionRotationModel],
  ) -> [String: Int] {
    var result: [String: Int] = [:]
    for champion in champions {
      result[champion.riotId] = 0
    }
    for rotation in rotations {
      for champion in Set(rotation.champions) {
        result[champion, default: 0] += 1
      }
    }
    return result
  }

  private func popularityByChampion(
    _ occurrencesByChampion: [String: Int],
  ) -> [String: Int] {
    let appearanceCounts = occurrencesByChampion.values.sorted(by: >)
    var popularityByAppearanceCount = [Int: Int]()

    if let mostPopularCount = appearanceCounts.first {
      popularityByAppearanceCount[mostPopularCount] = 1
    }
    for index in appearanceCounts.indices.dropFirst() {
      let (previousCount, nextCount) = (appearanceCounts[index - 1], appearanceCounts[index])
      if nextCount != previousCount {
        popularityByAppearanceCount[nextCount] = index + 1
      }
    }

    var result: [String: Int] = [:]
    for (champion, appearanceCount) in occurrencesByChampion {
      result[champion] = popularityByAppearanceCount[appearanceCount]!
    }
    return result
  }

  private func currentStreaksByChampion(
    _ champions: [ChampionModel],
    _ rotations: [RegularChampionRotationModel],
  ) throws -> [String: Int] {
    var result: [String: Int] = [:]
    for champion in champions {
      result[champion.riotId] = 0
    }

    let releaseDatesByChampion = try releaseDatesByChampion(champions: champions)
    var unresolvedChampions = Set(champions.map(\.riotId))
    let rotationsNewestToOldest = rotations.sorted { lhs, rhs in
      lhs.observedAt > rhs.observedAt
    }

    for rotation in rotationsNewestToOldest {
      let champions = Set(rotation.champions)

      for champion in unresolvedChampions {
        guard let releasedAt = releaseDatesByChampion[champion],
          rotation.observedAt >= releasedAt
        else {
          unresolvedChampions.remove(champion)
          continue
        }

        if champions.contains(champion) {
          if result[champion, default: 0] >= 0 {
            result[champion, default: 0] += 1
          } else {
            unresolvedChampions.remove(champion)
          }
        } else {
          if result[champion, default: 0] <= 0 {
            result[champion, default: 0] -= 1
          } else {
            unresolvedChampions.remove(champion)
          }
        }
      }

      if unresolvedChampions.isEmpty {
        break
      }
    }

    return result
  }

  private func releaseDatesByChampion(
    champions: [ChampionModel],
  ) throws -> [String: Date] {
    try champions.reduce(into: [:]) { result, champion in
      guard let releasedAt = champion.releasedAt else {
        throw ChampionHistoryStatisticsError.insufficientData(championId: champion.riotId)
      }
      result[champion.riotId] = releasedAt
    }
  }

}

private struct StatisticsData {
  let occurrences: [String: Int]
  let popularity: [String: Int]
  let currentStreaks: [String: Int]

  func result<T>(
    for championId: String,
    _ selectResults: KeyPath<StatisticsData, [String: T]>,
  ) throws -> T {
    guard let value = self[keyPath: selectResults][championId] else {
      throw ChampionHistoryStatisticsError.missingResult(championId: championId)
    }
    return value
  }
}

enum ChampionHistoryStatisticsError: Error, Equatable {
  case insufficientData(championId: String)
  case missingResult(championId: String)
}
