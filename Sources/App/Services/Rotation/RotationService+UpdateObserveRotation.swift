extension DefaultRotationService {
  func updateObserveRotation(slug: String, by userId: String, observing: Bool)
    async throws(ChampionRotationError)
  {
    let (watchlists, rotation) = try await getLocalData(userId: userId, slug: slug)
    guard let rotationId = rotation?.idString else {
      throw .rotationDataMissing(slug: slug)
    }
    if observing {
      watchlists.rotations.appendIfAbsent(rotationId)
    } else {
      watchlists.rotations.removeAll(rotationId)
    }
    try await saveWatchlists(watchlists)
  }

  private func getLocalData(userId: String, slug: String) async throws(ChampionRotationError)
    -> UpdateObserveRotationLocalData
  {
    do {
      let watchlists = try await appDb.userWatchlists(userId: userId)
      let rotation = try await appDb.regularRotation(slug: slug)
      return (watchlists, rotation)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  private func saveWatchlists(_ data: UserWatchlistsModel) async throws(ChampionRotationError) {
    do {
      try await appDb.saveUserWatchlists(data: data)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }
}

private typealias UpdateObserveRotationLocalData = (
  watchlists: UserWatchlistsModel,
  rotation: RegularChampionRotationModel?
)
