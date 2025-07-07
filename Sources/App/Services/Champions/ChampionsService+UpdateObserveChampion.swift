extension ChampionsService {
  func updateObserveChampion(riotId: String, by userId: String, observing: Bool)
    async throws(ChampionsError)
  {
    let (watchlists, champion) = try await getLocalData(userId: userId, riotId: riotId)
    guard let championId = champion?.idString else {
      throw .dataInvalidOrMissing(riotId: riotId)
    }
    if observing {
      watchlists.champions.appendIfAbsent(championId)
    } else {
      watchlists.champions.removeAll(championId)
    }
    try await saveWatchlists(watchlists)
  }

  private func getLocalData(userId: String, riotId: String) async throws(ChampionsError)
    -> UpdateObserveChampionLocalData
  {
    do {
      let watchlists = try await appDb.userWatchlists(userId: userId)
      let champion = try await appDb.champion(riotId: riotId)
      return (watchlists, champion)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  private func saveWatchlists(_ data: UserWatchlistsModel) async throws(ChampionsError) {
    do {
      try await appDb.saveUserWatchlists(data: data)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }
}

private typealias UpdateObserveChampionLocalData = (
  watchlists: UserWatchlistsModel,
  champion: ChampionModel?
)
