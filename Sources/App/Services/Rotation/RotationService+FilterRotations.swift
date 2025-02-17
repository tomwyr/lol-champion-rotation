extension DefaultRotationService {
  func filterRotations(by championName: String) async throws(ChampionRotationError)
    -> FilterRotationsResult
  {
    let localData = try await loadFilterRotationsData(championName)
    let imageUrls = try await fetchImageUrls(localData)
    let filteredRotations = try await createFilteredRotations(championName, localData, imageUrls)
    return FilterRotationsResult(
      rotations: filteredRotations
    )
  }

  private func loadFilterRotationsData(_ championName: String) async throws(ChampionRotationError)
    -> FilterRotationsLocalData
  {
    do {
      let champions = try await appDatabase.filterChampions(name: championName)
      let championIds = champions.map(\.riotId)
      let rotations = try await appDatabase.filterRegularRotations(withChampions: championIds)
      let allChampions = try await appDatabase.champions()
      return (rotations, allChampions)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  private func fetchImageUrls(_ localData: FilterRotationsLocalData)
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

  private func createFilteredRotations(
    _ championNameQuery: String,
    _ data: FilterRotationsLocalData,
    _ imageUrls: ChampionImageUrls
  ) async throws(ChampionRotationError) -> [FilteredRotation] {
    let championFactory = ChampionFactory(champions: data.champions, imageUrls: imageUrls)

    let championsByRiotId = data.champions.associateBy(\.riotId)
    func matchesQuery(riotId: String) -> Bool {
      guard let champion = championsByRiotId[riotId] else { return false }
      return champion.name.lowercased().contains(championNameQuery.lowercased())
    }

    return try await data.rotations.asyncMap { rotation async throws(ChampionRotationError) in
      let duration = try await getRotationDuration(rotation)
      let champions = try rotation.champions.filter(matchesQuery).map(championFactory.create)
      return FilteredRotation(duration: duration, champions: champions)
    }
  }

}

private typealias FilterRotationsLocalData = (
  rotations: [RegularChampionRotationModel],
  champions: [ChampionModel]
)
