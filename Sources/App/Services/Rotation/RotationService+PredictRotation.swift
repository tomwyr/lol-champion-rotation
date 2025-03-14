extension DefaultRotationService {
  func predictRotation() async throws(ChampionRotationError) -> ChampionRotationPrediction {
    let data = try await loadPredictRotationLocalData()
    let champions = try predictChampions(data)
    return try await createRotation(data, champions)
  }

  private func loadPredictRotationLocalData() async throws(ChampionRotationError)
    -> PredictRotationLocalData
  {
    let regularRotations: [RegularChampionRotationModel]
    let champions: [ChampionModel]
    do {
      regularRotations = try await appDatabase.regularRotations()
      champions = try await appDatabase.champions()
    } catch {
      throw .dataOperationFailed(cause: error)
    }
    return (regularRotations, champions)
  }

  private func predictChampions(_ data: PredictRotationLocalData)
    throws(ChampionRotationError) -> [String]
  {
    let champions = data.champions.map(\.riotId)
    let rotations = data.regularRotations.map(\.champions)
    guard let previousRotationId = data.regularRotations.first?.idString else {
      throw .rotationDataMissing
    }

    do {
      return try rotationForecast.predict(
        champions: champions,
        rotations: rotations,
        previousRotationId: previousRotationId
      )
    } catch {
      throw .predictionError(cause: error)
    }
  }

  private func createRotation(_ data: PredictRotationLocalData, _ predictedChampions: [String])
    async throws(ChampionRotationError) -> ChampionRotationPrediction
  {
    let champions = try createChampions(for: predictedChampions, models: data.champions)
    guard let currentRotation = data.regularRotations.first else {
      throw .rotationDataMissing
    }
    let duration = try await getRotationPredictionDuration(currentRotation)

    return ChampionRotationPrediction(
      duration: duration,
      champions: champions
    )
  }
}

private typealias PredictRotationLocalData = (
  regularRotations: [RegularChampionRotationModel],
  champions: [ChampionModel]
)
