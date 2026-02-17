extension ChampionsService {
  func searchChampions(championName: String) async throws -> SearchChampionsResult {
    let champions = try await appDb.filterChampions(name: championName)
    let regularRotation = try await appDb.currentRegularRotation()
    let beginnerRotation = try await appDb.currentBeginnerRotation()

    return try createSearchChampionsResult(
      championName, champions,
      regularRotation,
      beginnerRotation,
    )
  }

  private func createSearchChampionsResult(
    _ searchedName: String,
    _ champions: [ChampionModel],
    _ regularRotation: RegularChampionRotationModel?,
    _ beginnerRotation: BeginnerChampionRotationModel?,
  ) throws -> SearchChampionsResult {
    func createMatch(model: ChampionModel) throws -> SearchChampionsMatch {
      let champion = try createChampion(model: model)

      var availableIn = [ChampionRotationType]()
      let regularChampions = regularRotation?.champions ?? []
      if regularChampions.contains(model.riotId) {
        availableIn.append(.regular)
      }
      let beginnerChampions = beginnerRotation?.champions ?? []
      if beginnerChampions.contains(model.riotId) {
        availableIn.append(.beginner)
      }

      return SearchChampionsMatch(
        champion: champion,
        availableIn: availableIn
      )
    }

    let matches =
      try champions
      .map(createMatch)
      .sortedByMatchIndex(searchedName: searchedName)

    return SearchChampionsResult(
      matches: matches
    )
  }
}

extension [SearchChampionsMatch] {
  fileprivate func sortedByMatchIndex(searchedName: String) -> [SearchChampionsMatch] {
    let lowerCaseName = searchedName.lowercased()
    return sorted { element in
      element.champion.name.lowercased().range(of: lowerCaseName)?.lowerBound
    }
  }
}
