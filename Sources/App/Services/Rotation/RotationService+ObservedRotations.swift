extension DefaultRotationService {
  func observedRotations(by userId: String) async throws -> ObservedRotationsData {
    let userWatchlists = try await appDb.userWatchlists(userId: userId)
    let rotations = try await appDb.regularRotations(ids: userWatchlists.rotations)
    let currentRotation = try await appDb.currentRegularRotation()

    let observedRotations = try await rotations.asyncMapSequential { rotation in
      try await createRotation(rotation, currentRotation)
    }
    return ObservedRotationsData(rotations: observedRotations)
  }

  private func createRotation(
    _ rotation: RegularChampionRotationModel,
    _ currentRotation: RegularChampionRotationModel?,
  ) async throws -> ObservedRotation {
    let id = rotation.slug
    let duration = try await getRotationDuration(rotation)
    let current = rotation.idString == currentRotation?.idString
    let championImageUrls =
      seededSelector
      .select(from: rotation.champions, taking: 5)
      .map(imageUrlProvider.champion)

    return .init(
      id: id,
      duration: duration,
      current: current,
      championImageUrls: championImageUrls
    )
  }
}
