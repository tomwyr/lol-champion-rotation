extension DefaultRotationService {
  func currentRotationPrediction() async throws -> ChampionRotationPrediction? {
    guard let currentRotation = try await appDb.currentRegularRotation(),
      let currentRotationId = currentRotation.idString,
      let prediction = try await appDb.rotationPrediction(refRotationId: currentRotationId)
    else {
      return nil
    }
    let championModels = try await appDb.champions(riotIds: prediction.champions)

    let duration = try await getRotationPredictionDuration(currentRotation)
    let champions = try createChampions(for: prediction.champions, models: championModels)
    return ChampionRotationPrediction(
      duration: duration,
      champions: champions,
    )
  }
}
