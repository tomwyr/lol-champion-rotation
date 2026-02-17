extension DefaultRotationService {
  func updateObserveRotation(
    slug: String, by userId: String, observing: Bool,
  ) async throws -> Bool? {
    let watchlists = try await appDb.userWatchlists(userId: userId)
    guard let rotation = try await appDb.regularRotation(slug: slug) else {
      return nil
    }

    try updateWatchlist(watchlists, rotation, observing)
    try await appDb.saveUserWatchlists(data: watchlists)

    return observing
  }

  private func updateWatchlist(
    _ watchlists: UserWatchlistsModel,
    _ rotation: RegularChampionRotationModel,
    _ observing: Bool,
  ) throws {
    guard let rotationId = rotation.idString else {
      throw ChampionRotationError.rotationDataMissing(slug: rotation.slug)
    }
    if observing {
      watchlists.rotations.appendIfAbsent(rotationId)
    } else {
      watchlists.rotations.removeAll(rotationId)
    }
  }
}
