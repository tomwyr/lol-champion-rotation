extension ChampionsService {
  func searchChampions(championName: String) async throws(ChampionsError)
    -> SearchChampionsResult
  {
    let data = try await loadSearchChampionsLocalData(championName)
    return try createSearchChampionsResult(championName, data)
  }

  private func loadSearchChampionsLocalData(_ searchedName: String) async throws(ChampionsError)
    -> SearchChampionsLocalData
  {
    do {
      let champions = try await appDatabase.filterChampions(name: searchedName)
      let regularRotation = try await appDatabase.currentRegularRotation()
      let beginnerRotation = try await appDatabase.currentBeginnerRotation()
      return (champions, regularRotation, beginnerRotation)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  private func createSearchChampionsResult(_ searchedName: String, _ data: SearchChampionsLocalData)
    throws(ChampionsError) -> SearchChampionsResult
  {
    func createMatch(model: ChampionModel) throws(ChampionsError) -> SearchChampionsMatch {
      let champion = try createChampion(model: model)

      var availableIn = [ChampionRotationType]()
      let regularChampions = data.regularRotation?.champions ?? []
      if regularChampions.contains(model.riotId) {
        availableIn.append(.regular)
      }
      let beginnerChampions = data.beginnerRotation?.champions ?? []
      if beginnerChampions.contains(model.riotId) {
        availableIn.append(.beginner)
      }

      return SearchChampionsMatch(
        champion: champion,
        availableIn: availableIn
      )
    }

    let matches = try data.champions
      .map(createMatch)
      .sortedByMatchIndex(searchedName: searchedName)

    return SearchChampionsResult(
      matches: matches
    )
  }
}

extension [SearchChampionsMatch] {
  func sortedByMatchIndex(searchedName: String) -> [SearchChampionsMatch] {
    let lowerCaseName = searchedName.lowercased()
    return sorted(byComparable: { element in
      element.champion.name.lowercased().range(of: lowerCaseName)?.lowerBound
    })
  }
}

private typealias SearchChampionsLocalData = (
  champions: [ChampionModel],
  regularRotation: RegularChampionRotationModel?,
  beginnerRotation: BeginnerChampionRotationModel?
)
