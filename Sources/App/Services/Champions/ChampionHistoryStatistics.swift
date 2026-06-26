import Foundation

struct ChampionHistoryStatistics {
  func calculate(
    champions: [ChampionModel],
    rotations: [RegularChampionRotationModel],
  ) throws -> [ChampionHistoryStatisticsModel] {
    try champions.map { champion in
      ChampionHistoryStatisticsModel(
        championRiotId: champion.riotId,
        occurrences: occurrences(of: champion, in: rotations),
        popularity: try ChampionPopularity().calculate(
          for: champion,
          champions: champions,
          rotations: rotations
        ),
        currentStreak: try currentStreak(of: champion, in: rotations),
      )
    }
  }

  private func occurrences(
    of champion: ChampionModel,
    in rotations: [RegularChampionRotationModel],
  ) -> Int {
    rotations.count { $0.champions.contains(champion.riotId) }
  }

  private func currentStreak(
    of champion: ChampionModel,
    in rotations: [RegularChampionRotationModel],
  ) throws -> Int {
    guard let releasedAt = champion.releasedAt else {
      throw ChampionHistoryStatisticsError.insufficientData(championRiotId: champion.riotId)
    }

    let eligibleRotations = rotations.filter { $0.observedAt >= releasedAt }
    guard let firstRotation = eligibleRotations.first else {
      return 0
    }

    let present = firstRotation.champions.contains(champion.riotId)
    let streak = eligibleRotations.prefix {
      $0.champions.contains(champion.riotId) == present
    }.count

    return present ? streak : -streak
  }
}

enum ChampionHistoryStatisticsError: Error {
  case insufficientData(championRiotId: String)
}
