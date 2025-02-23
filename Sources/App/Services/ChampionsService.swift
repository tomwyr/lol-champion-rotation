struct ChampionsService {
  let imageUrlProvider: ImageUrlProvider
  let appDatabase: AppDatabase

  func searchChampions(championName: String) async throws(ChampionsError)
    -> SearchChampionsResult
  {
    let data = try await loadSearchChampionsLocalData(championName)
    let imageUrls = try await getImageUrls(data.champions)
    return try createSearchChampionsResult(championName, data, imageUrls)
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

  private func createSearchChampionsResult(
    _ searchedName: String,
    _ data: SearchChampionsLocalData,
    _ imageUrls: ChampionImageUrls
  ) throws(ChampionsError) -> SearchChampionsResult {
    let championFactory = ChampionFactory(
      champions: data.champions,
      imageUrls: imageUrls,
      wrapError: ChampionsError.championError
    )

    func createMatch(riotId: String) throws(ChampionsError) -> SearchChampionsMatch {
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

    let matches = try data.champions.map(\.riotId)
      .map(createMatch)
      .sortedByMatchIndex(searchedName: searchedName)

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

extension [SearchChampionsMatch] {
  func sortedByMatchIndex(searchedName: String) -> [SearchChampionsMatch] {
    let lowerCaseName = searchedName.lowercased()
    return sorted(byComparable: { element in
      element.champion.name.lowercased().range(of: lowerCaseName)?.lowerBound
    })
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
