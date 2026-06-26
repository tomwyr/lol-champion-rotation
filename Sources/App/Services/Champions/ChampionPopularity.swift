import Foundation

/// Ranks champions by their recent regular-rotation participation.
///
/// Each appearance contributes to the score, recent appearances contribute
/// more, and newly released champions receive a bounded boost that fades as
/// more rotations occur after their release.
struct ChampionPopularity {
  /// Number of rotations after which an observation's weight is halved.
  static let halfLife = 13.0
  /// Number of eligible rotations after which the new-champion boost is halved.
  static let newChampionHalfLife = 4.0
  /// Maximum number of newest rotations included in the calculation.
  static let rotationsLimit = 104

  func calculate(
    for champion: ChampionModel,
    champions: [ChampionModel],
    rotations: [RegularChampionRotationModel],
  ) throws(ChampionPopularityError) -> Int {
    guard champion.releasedAt != nil else {
      throw .insufficientData
    }

    let recentRotations = rotations.prefix(Self.rotationsLimit)
    let scores = champions.compactMap { champion in
      score(for: champion, rotations: recentRotations)
    }
    guard let championScore = scores.first(where: { $0.champion == champion.riotId })?.value else {
      throw .insufficientData
    }

    // Competition ranking: equal scores share a position.
    return scores.count { $0.value > championScore } + 1
  }

  private func score(
    for champion: ChampionModel,
    rotations: ArraySlice<RegularChampionRotationModel>,
  ) -> (champion: String, value: Double)? {
    guard let releasedAt = champion.releasedAt else {
      return nil
    }

    let eligibleRotations = rotations.count { $0.observedAt >= releasedAt }
    let rotationsSinceRelease = max(eligibleRotations - 1, 0)
    let newChampionBoost = pow(2, -Double(rotationsSinceRelease) / Self.newChampionHalfLife)

    var value = 0.0
    for (age, rotation) in rotations.enumerated() where rotation.observedAt >= releasedAt {
      if rotation.champions.contains(champion.riotId) {
        let recencyWeight = pow(2, -Double(age) / Self.halfLife)
        value += recencyWeight * (1 + newChampionBoost)
      }
    }

    return (champion.riotId, value)
  }
}

enum ChampionPopularityError: Error {
  case insufficientData
}
