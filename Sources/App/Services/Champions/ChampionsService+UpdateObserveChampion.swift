extension ChampionsService {
  func updateObserveChampion(
    riotId: String, by userId: String, observing: Bool,
  ) async throws -> Bool? {
    let watchlists = try await appDb.userWatchlists(userId: userId)
    guard let champion = try await appDb.champion(riotId: riotId) else {
      return nil
    }

    try updateWatchlist(watchlists, champion, observing)
    try await appDb.saveUserWatchlists(data: watchlists)

    return observing
  }

  private func updateWatchlist(
    _ watchlists: UserWatchlistsModel,
    _ champion: ChampionModel,
    _ observing: Bool,
  ) throws {
    guard let championId = champion.idString else {
      throw ChampionsError.dataInvalidOrMissing(riotId: champion.riotId)
    }
    if observing {
      watchlists.champions.appendIfAbsent(championId)
    } else {
      watchlists.champions.removeAll(championId)
    }
  }
}
