extension ChampionsService {
  func updateObserveChampion(championId: String, by userId: String, observing: Bool)
    async throws(ChampionsError)
  {
    let data = try await getWatchlists(userId)
    if observing {
      data.champions.appendIfAbsent(championId)
    } else {
      data.champions.removeAll(championId)
    }
    try await saveWatchlists(data)
  }

  private func getWatchlists(_ userId: String) async throws(ChampionsError) -> UserWatchlistsModel {
    do {
      return try await appDb.userWatchlists(userId: userId)
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
