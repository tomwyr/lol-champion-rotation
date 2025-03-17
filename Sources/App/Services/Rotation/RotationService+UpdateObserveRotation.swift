extension DefaultRotationService {
  func updateObserveRotation(rotationId: String, by userId: String, observing: Bool)
    async throws(ChampionRotationError)
  {
    let data = try await getWatchlists(userId)
    if observing {
      data.rotations.appendIfAbsent(rotationId)
    } else {
      data.rotations.removeAll(rotationId)
    }
    try await saveWatchlists(data)
  }

  private func getWatchlists(_ userId: String) async throws(ChampionRotationError)
    -> UserWatchlistsModel
  {
    do {
      return try await appDatabase.userWatchlists(userId: userId)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  private func saveWatchlists(_ data: UserWatchlistsModel) async throws(ChampionRotationError) {
    do {
      try await appDatabase.saveUserWatchlists(data: data)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }
}
