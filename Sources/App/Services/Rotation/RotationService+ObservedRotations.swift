extension DefaultRotationService {
  func observedRotations(by userId: String) async throws(ChampionRotationError)
    -> ObservedRotationsData
  {
    let data = try await loadObservedRotationsLocalData(userId)
    return try await createObservedRotations(userId, data)
  }

  private func loadObservedRotationsLocalData(_ userId: String) async throws(ChampionRotationError)
    -> ObservedRotationsLocalData
  {
    let rotations: [RegularChampionRotationModel]
    let currentRotation: RegularChampionRotationModel?
    do {
      let userWatchlists = try await appDb.userWatchlists(userId: userId)
      rotations = try await appDb.regularRotations(ids: userWatchlists.rotations)
      currentRotation = try await appDb.currentRegularRotation()
      return (rotations, currentRotation)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  private func createObservedRotations(_ userId: String, _ data: ObservedRotationsLocalData)
    async throws(ChampionRotationError) -> ObservedRotationsData
  {
    let currentRotation = data.currentRotation
    let rotations = try await data.rotations.asyncMapSequential {
      rotation throws(ChampionRotationError) in
      guard let result = try await createRotation(rotation, currentRotation)
      else {
        throw .observedRotationDataInvalid(userId: userId)
      }
      return result
    }
    return ObservedRotationsData(rotations: rotations)
  }

  private func createRotation(
    _ rotation: RegularChampionRotationModel,
    _ currentRotation: RegularChampionRotationModel?
  ) async throws(ChampionRotationError) -> ObservedRotation? {
    let id = rotation.slug
    let duration = try await getRotationDuration(rotation)
    let current = rotation.idString == currentRotation?.idString
    let championImageUrls = seededSelector.select(from: rotation.champions, taking: 5)
      .map(imageUrlProvider.champion)

    return .init(
      id: id,
      duration: duration,
      current: current,
      championImageUrls: championImageUrls
    )
  }
}

private typealias ObservedRotationsLocalData = (
  rotations: [RegularChampionRotationModel],
  currentRotation: RegularChampionRotationModel?
)
