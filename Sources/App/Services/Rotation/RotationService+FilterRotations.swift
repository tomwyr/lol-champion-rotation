extension DefaultRotationService {
  func filterRotations(by championName: String) async throws(ChampionRotationError)
    -> FilterRotationsResult
  {
    let localData = try await loadFilterRotationsData(championName)
    let imageUrls = try await getImageUrls(localData)
    let filteredRotations = try await createRegularRotations(championName, localData, imageUrls)
    let beginnerRotation = try await createBeginnerRotation(championName, localData, imageUrls)
    return FilterRotationsResult(
      regularRotations: filteredRotations,
      beginnerRotation: beginnerRotation
    )
  }

  private func loadFilterRotationsData(_ championName: String) async throws(ChampionRotationError)
    -> FilterRotationsLocalData
  {
    do {
      let currentRotationId = try await appDatabase.currentRegularRotation()?.id?.uuidString
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

  private func getImageUrls(_ localData: FilterRotationsLocalData)
    async throws(ChampionRotationError) -> ChampionImageUrls
  {
    do {
      let championIds = localData.champions.map(\.riotId)
      let imageUrls = try await imageUrlProvider.champions(with: championIds)
      let urlsById = Dictionary(uniqueKeysWithValues: zip(championIds, imageUrls))
      return ChampionImageUrls(imageUrlsByChampionId: urlsById)
    } catch {
      throw .championImagesUnavailable(cause: error)
    }
  }

  private func createRegularRotations(
    _ championNameQuery: String,
    _ data: FilterRotationsLocalData,
    _ imageUrls: ChampionImageUrls
  ) async throws(ChampionRotationError) -> [FilteredRegularRotation] {
    let championFactory = ChampionFactory(
      champions: data.champions,
      imageUrls: imageUrls,
      wrapError: ChampionRotationError.championError
    )

    let championsByRiotId = data.champions.associateBy(\.riotId)
    func matchesQuery(riotId: String) -> Bool {
      guard let champion = championsByRiotId[riotId] else { return false }
      return champion.name.lowercased().contains(championNameQuery.lowercased())
    }

    return try await data.regularRotations.asyncMap {
      rotation async throws(ChampionRotationError) in
      let champions = try rotation.champions.filter(matchesQuery).map(championFactory.create)
      let duration = try await getRotationDuration(rotation)
      let current = rotation.id?.uuidString == data.currentRotationId
      return FilteredRegularRotation(champions: champions, duration: duration, current: current)
    }
  }

  private func createBeginnerRotation(
    _ championNameQuery: String,
    _ data: FilterRotationsLocalData,
    _ imageUrls: ChampionImageUrls
  ) async throws(ChampionRotationError) -> FilteredBeginnerRotation? {
    guard let rotation = data.beginnerRotation else {
      return nil
    }

    let championFactory = ChampionFactory(
      champions: data.champions,
      imageUrls: imageUrls,
      wrapError: ChampionRotationError.championError
    )

    let championsByRiotId = data.champions.associateBy(\.riotId)
    func matchesQuery(riotId: String) -> Bool {
      guard let champion = championsByRiotId[riotId] else { return false }
      return champion.name.lowercased().contains(championNameQuery.lowercased())
    }

    let champions = try rotation.champions.filter(matchesQuery).map(championFactory.create)
    return FilteredBeginnerRotation(champions: champions)
  }
}

private typealias FilterRotationsLocalData = (
  currentRotationId: String?,
  regularRotations: [RegularChampionRotationModel],
  beginnerRotation: BeginnerChampionRotationModel?,
  champions: [ChampionModel]
)
