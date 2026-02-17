extension DefaultRotationService {
  func predictRotation() async throws -> ChampionRotationPrediction {
    if let existing = try await loadExistingPrediction() {
      existing
    } else {
      try await generatePrediction()
    }
  }
}

extension DefaultRotationService {
  private func loadExistingPrediction() async throws -> ChampionRotationPrediction? {
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

extension DefaultRotationService {
  private func generatePrediction() async throws -> ChampionRotationPrediction {
    let regularRotations = try await appDb.regularRotations()
    let champions = try await appDb.champions()

    let predictedChampions = try predictChampions(regularRotations, champions)
    let prediction = try await createPrediction(regularRotations, champions, predictedChampions)
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
