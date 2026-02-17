struct ChampionPopularity {
  func calculate(
    for champion: ChampionModel,
    data rotationsCount: [ChampionRotationsCountModel],
  ) throws(ChampionPopularityError) -> Int {
    var championScore = 0.0
    var scores = [Double]()
    for count in rotationsCount {
      let score = try calcPopularityScore(count)
      scores.append(score)
      if count.champion == champion.riotId {
        championScore = score
      }
    }
    return scores.count { $0 > championScore } + 1
  }

  private func calcPopularityScore(
    _ count: ChampionRotationsCountModel,
  ) throws(ChampionPopularityError) -> Double {
    guard let afterRelease = count.afterRelease else {
      throw .insufficientData
    }
    var relativeScore = 0.0
    if afterRelease > 0 {
      relativeScore = Double(count.presentIn) / Double(afterRelease)
    }
    var globalScore = 0.0
    if count.total > 0 {
      globalScore = Double(count.presentIn) / Double(count.total)
    }
    return 0.5 * relativeScore + 0.5 * globalScore
  }
}

enum ChampionPopularityError: Error {
  case insufficientData
}
