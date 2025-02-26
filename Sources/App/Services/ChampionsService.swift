struct ChampionsService {
  let imageUrlProvider: ImageUrlProvider
  let appDatabase: AppDatabase

  func getChampionDetails(championId: String) async throws(ChampionsError) -> ChampionDetails? {
    let data = try await loadChampionDetailsData(championId)
    guard let champion = data.champion else {
      return nil
    }
    let imageUrls = try await getImageUrls([champion])
    return try await createChampionDetails(championId, champion, imageUrls, data)
  }

  private func loadChampionDetailsData(_ championId: String) async throws(ChampionsError)
    -> ChampionDetailsLocalData
  {
    do {
      let champion = try await appDatabase.champion(id: championId)
      let regularRotation = try await appDatabase.mostRecentRegularRotation(
        withChampion: championId)
      let beginnerRotation = try await appDatabase.mostRecentBeginnerRotation(
        withChampion: championId)
      let currentRegularRotation = try await appDatabase.currentRegularRotation()
      let currentBeginnerRotation = try await appDatabase.currentBeginnerRotation()
      return (
        champion, regularRotation, beginnerRotation, currentRegularRotation, currentBeginnerRotation
      )
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  private func createChampionDetails(
    _ championId: String,
    _ champion: ChampionModel,
    _ imageUrls: ChampionImageUrls,
    _ data: ChampionDetailsLocalData
  )
    async throws(ChampionsError) -> ChampionDetails?
  {
    let championFactory = ChampionFactory(
      champions: [champion],
      imageUrls: imageUrls,
      wrapError: ChampionsError.championError
    )

    let rotationsAvailability = createRotationsAvailability(data)

    return try championFactory.createDetails(
      riotId: championId,
      rotationsAvailability: rotationsAvailability
    )
  }

  private func createRotationsAvailability(_ data: ChampionDetailsLocalData)
    -> [ChampionDetailsAvailability]
  {
    let (_, regularRotation, beginnerRotation, currentRegularRotation, currentBeginnerRotation) =
      data

    var rotationsAvailability = [ChampionDetailsAvailability]()
    rotationsAvailability.append(
      .init(
        rotationType: .regular,
        lastAvailable: regularRotation?.observedAt,
        current: regularRotation?.id != nil && regularRotation?.id == currentRegularRotation?.id
      ))
    rotationsAvailability.append(
      .init(
        rotationType: .beginner,
        lastAvailable: beginnerRotation?.observedAt,
        current: beginnerRotation?.id != nil
          && beginnerRotation?.id == currentBeginnerRotation?.id
      ))

    return rotationsAvailability
  }

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

private typealias ChampionDetailsLocalData = (
  champion: ChampionModel?,
  regularRotation: RegularChampionRotationModel?,
  beginnerRotation: BeginnerChampionRotationModel?,
  currentRegularRotation: RegularChampionRotationModel?,
  currentBeginnerRotation: BeginnerChampionRotationModel?
)

private typealias SearchChampionsLocalData = (
  champions: [ChampionModel],
  regularRotation: RegularChampionRotationModel?,
  beginnerRotation: BeginnerChampionRotationModel?
)
