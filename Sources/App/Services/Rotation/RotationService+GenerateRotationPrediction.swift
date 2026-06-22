extension DefaultRotationService {
  func generateRotationPrediction() async throws -> ChampionRotationPrediction {
    let regularRotations = try await appDb.regularRotations()
    let champions = try await appDb.champions()

    let predictedChampions = try predictChampions(regularRotations, champions)
    let prediction = try await createPrediction(
      regularRotations, champions, predictedChampions
    )
    try await savePrediction(regularRotations, predictedChampions)

    return prediction
  }

  private func predictChampions(
    _ regularRotations: [RegularChampionRotationModel],
    _ champions: [ChampionModel],
  ) throws -> [String] {
    let championIds = champions.map(\.riotId)
    let rotations = regularRotations.map(\.champions)
    guard let refRotationId = regularRotations.first?.idString else {
      throw ChampionRotationError.rotationDataMissing()
    }

    return try rotationForecast.predict(
      champions: championIds,
      rotations: rotations,
      refRotationId: refRotationId
    )
  }

  private func createPrediction(
    _ regularRotations: [RegularChampionRotationModel],
    _ champions: [ChampionModel],
    _ predictedChampions: [String],
  ) async throws -> ChampionRotationPrediction {
    let champions = try createChampions(for: predictedChampions, models: champions)
    guard let currentRotation = regularRotations.first else {
      throw ChampionRotationError.rotationDataMissing()
    }
    let duration = try await getRotationPredictionDuration(currentRotation)

    return ChampionRotationPrediction(
      duration: duration,
      champions: champions
    )
  }

  private func savePrediction(
    _ regularRotations: [RegularChampionRotationModel],
    _ predictedChampions: [String],
  ) async throws {
    guard let refRotationId = regularRotations.first?.id else {
      throw ChampionRotationError.rotationDataMissing()
    }
    let data = ChampionRotationPredictionModel(
      refRotationId: refRotationId,
      champions: predictedChampions,
    )
    try await appDb.saveRotationPrediction(data: data)
  }
}
