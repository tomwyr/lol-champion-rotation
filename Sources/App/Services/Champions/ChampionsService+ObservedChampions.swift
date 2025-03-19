extension ChampionsService {
  func observedChampions(by userId: String) async throws(ChampionsError)
    -> ObservedChampionsData
  {
    let data = try await loadObservedChampionsLocalData(userId)
    return try await createObservedChampions(userId, data)
  }

  private func loadObservedChampionsLocalData(_ userId: String) async throws(ChampionsError)
    -> ObservedChampionsLocalData
  {
    do {
      let userWatchlists = try await appDb.userWatchlists(userId: userId)
      let champions = try await appDb.champions(ids: userWatchlists.champions)
      let currentRotation = try await appDb.currentRegularRotation()
      return (champions, currentRotation)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  private func createObservedChampions(_ userId: String, _ data: ObservedChampionsLocalData)
    async throws(ChampionsError) -> ObservedChampionsData
  {
    let currentRotation = data.currentRotation
    let champions = try await data.champions.asyncMapSequential {
      champion throws(ChampionsError) in
      guard let result = try await createChampion(champion, currentRotation)
      else {
        throw .observedChampionDataInvalid(userId: userId)
      }
      return result
    }
    return ObservedChampionsData(champions: champions)
  }

  private func createChampion(
    _ champion: ChampionModel,
    _ currentRotation: RegularChampionRotationModel?
  ) async throws(ChampionsError) -> ObservedChampion? {
    guard let id = champion.idString else {
      return nil
    }

    let name = champion.name
    let current = currentRotation?.champions.contains(champion.riotId) ?? false
    let imageUrl = imageUrlProvider.champion(with: champion.riotId)

    return .init(
      id: id,
      name: name,
      current: current,
      imageUrl: imageUrl
    )
  }
}

private typealias ObservedChampionsLocalData = (
  champions: [ChampionModel],
  currentRotation: RegularChampionRotationModel?
)
