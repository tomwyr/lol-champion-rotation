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
        popularity: try popularity(of: champion, among: champions, in: rotations),
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

  private func popularity(
    of champion: ChampionModel,
    among champions: [ChampionModel],
    in rotations: [RegularChampionRotationModel],
  ) throws -> Int {
    guard let releasedAt = champion.releasedAt else {
      throw ChampionHistoryStatisticsError.insufficientData(championRiotId: champion.riotId)
    }

    let appearanceCount = rotations.count { rotation in
      rotation.observedAt >= releasedAt && rotation.champions.contains(champion.riotId)
    }
    let higherAppearanceCounts = champions.compactMap { champion -> Int? in
      guard let releasedAt = champion.releasedAt else {
        return nil
      }
      return rotations.count { rotation in
        rotation.observedAt >= releasedAt && rotation.champions.contains(champion.riotId)
      }
    }

    // Competition ranking: equal appearance counts share a position.
    return higherAppearanceCounts.count { $0 > appearanceCount } + 1
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

enum ChampionHistoryStatisticsError: Error, Equatable {
  case insufficientData(championRiotId: String)
}
