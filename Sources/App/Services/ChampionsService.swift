struct ChampionsService {
  let imageUrlProvider: ImageUrlProvider
  let appDatabase: AppDatabase

  func searchChampions(name championName: String) async throws(ChampionsError)
    -> SearchChampionsResult
  {
    let data = try await loadSearchChampionsLocalData(championName: championName)
    let imageUrls = try await getImageUrls(data.champions)
    return try createSearchChampionsResult(data, imageUrls)
  }

  private func loadSearchChampionsLocalData(championName: String) async throws(ChampionsError)
    -> SearchChampionsLocalData
  {
    do {
      let champions = try await appDatabase.filterChampions(name: championName)
      let regularRotation = try await appDatabase.currentRegularRotation()
      let beginnerRotation = try await appDatabase.currentBeginnerRotation()
      return (champions, regularRotation, beginnerRotation)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  private func createSearchChampionsResult(
    _ data: SearchChampionsLocalData,
    _ imageUrls: ChampionImageUrls
  ) throws(ChampionsError) -> SearchChampionsResult {
    let championFactory = ChampionFactory(
      champions: data.champions,
      imageUrls: imageUrls,
      wrapError: ChampionsError.championError
    )

    let matches = try data.champions.map(\.riotId).map { riotId throws(ChampionsError) in
      let champion = try championFactory.create(riotId: riotId)

      var availableIn = [ChampionRotationType]()
      let regularChampions = data.regularRotation?.champions ?? []
      if regularChampions.contains(riotId) {
        availableIn.append(.regular)
      }
      let beginnerChampions = data.beginnerRotation?.champions ?? []
      if beginnerChampions.contains(riotId) {
        availableIn.append(.beginner)
      }

      return SearchChampionsMatch(
        champion: champion,
        availableIn: availableIn
      )
    }

    return SearchChampionsResult(
      matches: matches
    )
  }

  private func getImageUrls(_ champions: [ChampionModel])
    async throws(ChampionsError) -> ChampionImageUrls
  {
    do {
      let championIds = champions.map(\.riotId)
      let imageUrls = try await imageUrlProvider.champions(with: championIds)
      let urlsById = Dictionary(uniqueKeysWithValues: zip(championIds, imageUrls))
      return ChampionImageUrls(imageUrlsByChampionId: urlsById)
    } catch {
      throw .championImagesUnavailable(cause: error)
    }
  }
}

enum ChampionsError: Error {
  case championImagesUnavailable(cause: Error)
  case dataOperationFailed(cause: Error)
  case championError(cause: ChampionError)
}

private typealias SearchChampionsLocalData = (
  champions: [ChampionModel],
  regularRotation: RegularChampionRotationModel?,
  beginnerRotation: BeginnerChampionRotationModel?
)
