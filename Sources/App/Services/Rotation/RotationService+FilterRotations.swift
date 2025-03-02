extension DefaultRotationService {
  func filterRotations(by championName: String) async throws(ChampionRotationError)
    -> FilterRotationsResult
  {
    let localData = try await loadFilterRotationsData(championName)
    let filteredRotations = try await createRegularRotations(championName, localData)
    let beginnerRotation = try await createBeginnerRotation(championName, localData)
    return FilterRotationsResult(
      regularRotations: filteredRotations,
      beginnerRotation: beginnerRotation
    )
  }

  private func loadFilterRotationsData(_ championName: String) async throws(ChampionRotationError)
    -> FilterRotationsLocalData
  {
    do {
      let currentRotationId = try await appDatabase.currentRegularRotation()?.idString
      let champions = try await appDatabase.filterChampions(name: championName)
      let championIds = champions.map(\.riotId)
      let regularRotations =
        try await appDatabase.filterRegularRotations(withChampions: championIds)
      let beginnerRotation =
        try await appDatabase.filterMostRecentBeginnerRotation(withChampions: championIds)
      let allChampions = try await appDatabase.champions()
      return (currentRotationId, regularRotations, beginnerRotation, allChampions)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  private func createRegularRotations(_ championNameQuery: String, _ data: FilterRotationsLocalData)
    async throws(ChampionRotationError) -> [FilteredRegularRotation]
  {
    return try await data.regularRotations.asyncMap {
      rotation async throws(ChampionRotationError) in
      let matchingRiotIds = filterChampions(rotation.champions, by: championNameQuery, data: data)
      let champions = try createChampions(for: matchingRiotIds, models: data.champions)
      let duration = try await getRotationDuration(rotation)
      let current = rotation.idString == data.currentRotationId
      return FilteredRegularRotation(champions: champions, duration: duration, current: current)
    }
  }

  private func createBeginnerRotation(_ championNameQuery: String, _ data: FilterRotationsLocalData)
    async throws(ChampionRotationError) -> FilteredBeginnerRotation?
  {
    guard let rotation = data.beginnerRotation else {
      return nil
    }
    let matchingRiotIds = filterChampions(rotation.champions, by: championNameQuery, data: data)
    let champions = try createChampions(for: matchingRiotIds, models: data.champions)
    return FilteredBeginnerRotation(champions: champions)
  }

  private func filterChampions(
    _ champions: [String], by query: String,
    data: FilterRotationsLocalData
  ) -> [String] {
    let championsByRiotId = data.champions.associateBy(\.riotId)
    return champions.filter { riotId in
      guard let champion = championsByRiotId[riotId] else { return false }
      return champion.name.lowercased().contains(query.lowercased())
    }
  }
}

private typealias FilterRotationsLocalData = (
  currentRotationId: String?,
  regularRotations: [RegularChampionRotationModel],
  beginnerRotation: BeginnerChampionRotationModel?,
  champions: [ChampionModel]
)
