extension ChampionsService {
  func observedChampions(by userId: String) async throws -> ObservedChampionsData {
    let currentRotation = try await appDb.currentRegularRotation()
    let userWatchlists = try await appDb.userWatchlists(userId: userId)
    let champions = try await appDb.champions(ids: userWatchlists.champions)

    let observedChampions = try await champions.asyncMapSequential { champion in
      try await createChampion(champion, currentRotation)
    }
    return ObservedChampionsData(champions: observedChampions)
  }

  private func createChampion(
    _ champion: ChampionModel,
    _ currentRotation: RegularChampionRotationModel?
  ) async throws -> ObservedChampion {
    let id = champion.riotId
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
