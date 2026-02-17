extension DefaultRotationService {
  func filterRotations(by championName: String) async throws -> FilterRotationsResult {
    let data = try await loadFilterRotationsData(championName)
    let filteredRotations = try await createRegularRotations(championName, data)
    let beginnerRotation = try await createBeginnerRotation(championName, data)
    return FilterRotationsResult(
      regularRotations: filteredRotations,
      beginnerRotation: beginnerRotation
    )
  }

  private func loadFilterRotationsData(
    _ championName: String,
  ) async throws -> FilterRotationsLocalData {
    let currentRotationId = try await appDb.currentRegularRotation()?.idString
    let champions = try await appDb.filterChampions(name: championName)
    let championIds = champions.map(\.riotId)
    let regularRotations = try await appDb.filterRegularRotations(withChampions: championIds)
    let beginnerRotation =
      try await appDb.filterMostRecentBeginnerRotation(withChampions: championIds)
    let allChampions = try await appDb.champions()
    return (currentRotationId, regularRotations, beginnerRotation, allChampions)
  }

  private func createRegularRotations(
    _ championNameQuery: String,
    _ data: FilterRotationsLocalData,
  ) async throws -> [FilteredRegularRotation] {
    try await data.regularRotations.asyncMapSequential { rotation in
      let matchingRiotIds = filterChampions(
        from: rotation.champions,
        by: championNameQuery,
        allChampions: data.allChampions,
      )
      let champions = try createChampions(for: matchingRiotIds, models: data.allChampions)
      let duration = try await getRotationDuration(rotation)
      let current = rotation.idString == data.currentRotationId
      return FilteredRegularRotation(champions: champions, duration: duration, current: current)
    }
  }

  private func createBeginnerRotation(
    _ championNameQuery: String,
    _ data: FilterRotationsLocalData,
  ) async throws -> FilteredBeginnerRotation? {
    guard let rotation = data.beginnerRotation else {
      return nil
    }
    let matchingRiotIds = filterChampions(
      from: rotation.champions,
      by: championNameQuery,
      allChampions: data.allChampions,
    )
    let champions = try createChampions(for: matchingRiotIds, models: data.allChampions)
    return FilteredBeginnerRotation(champions: champions)
  }

  private func filterChampions(
    from championIds: [String], by query: String,
    allChampions: [ChampionModel],
  ) -> [String] {
    let championsByRiotId = allChampions.associatedBy(key: \.riotId)
    return championIds.filter { riotId in
      guard let champion = championsByRiotId[riotId] else { return false }
      return champion.name.lowercased().contains(query.lowercased())
    }
  }
}

private typealias FilterRotationsLocalData = (
  currentRotationId: String?,
  regularRotations: [RegularChampionRotationModel],
  beginnerRotation: BeginnerChampionRotationModel?,
  allChampions: [ChampionModel],
)
