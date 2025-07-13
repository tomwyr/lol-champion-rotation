extension DefaultRotationService {
  func predictRotation() async throws(ChampionRotationError) -> ChampionRotationPrediction {
    if let existing = try await loadExistingPrediction() {
      existing
    } else {
      try await generatePrediction()
    }
  }
}

extension DefaultRotationService {
  private func loadExistingPrediction() async throws(ChampionRotationError)
    -> ChampionRotationPrediction?
  {
    guard let data = try await loadExistingLocalData() else {
      return nil
    }
    return try await createPrediction(data)
  }

  private func loadExistingLocalData() async throws(ChampionRotationError)
    -> LoadPredictionLocalData?
  {
    do {
      guard let currentRotation = try await appDb.currentRegularRotation(),
        let currentRotationId = currentRotation.idString,
        let prediction = try await appDb.rotationPrediction(previousRotationId: currentRotationId)
      else {
        return nil
      }

      let champions = try await appDb.champions(riotIds: prediction.champions)

      return (currentRotation, prediction, champions)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  private func createPrediction(_ data: LoadPredictionLocalData)
    async throws(ChampionRotationError)
    -> ChampionRotationPrediction
  {
    let duration = try await getRotationPredictionDuration(data.currentRotation)
    let champions = try createChampions(for: data.prediction.champions, models: data.champions)

    return ChampionRotationPrediction(
      duration: duration,
      champions: champions,
    )
  }
}

extension DefaultRotationService {
  private func generatePrediction() async throws(ChampionRotationError)
    -> ChampionRotationPrediction
  {
    let data = try await loadGenerateLocalData()
    let champions = try predictChampions(data)
    let prediction = try await createPrediction(data, champions)
    try await savePrediction(data, champions)
    return prediction
  }

  private func loadGenerateLocalData() async throws(ChampionRotationError)
    -> GeneratePredictionLocalData
  {
    let regularRotations: [RegularChampionRotationModel]
    let champions: [ChampionModel]
    do {
      regularRotations = try await appDb.regularRotations()
      champions = try await appDb.champions()
    } catch {
      throw .dataOperationFailed(cause: error)
    }
    return (regularRotations, champions)
  }

  private func predictChampions(_ data: GeneratePredictionLocalData)
    throws(ChampionRotationError) -> [String]
  {
    let champions = data.champions.map(\.riotId)
    let rotations = data.regularRotations.map(\.champions)
    guard let previousRotationId = data.regularRotations.first?.idString else {
      throw .rotationDataMissing()
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

  private func createPrediction(_ data: GeneratePredictionLocalData, _ predictedChampions: [String])
    async throws(ChampionRotationError) -> ChampionRotationPrediction
  {
    let champions = try createChampions(for: predictedChampions, models: data.champions)
    guard let currentRotation = data.regularRotations.first else {
      throw .rotationDataMissing()
    }
    let duration = try await getRotationPredictionDuration(currentRotation)

    return ChampionRotationPrediction(
      duration: duration,
      champions: champions
    )
  }

  private func savePrediction(
    _ localData: GeneratePredictionLocalData,
    _ predictedChampions: [String],
  ) async throws(ChampionRotationError) {
    guard let previousRotationId = localData.regularRotations.first?.id else {
      throw .rotationDataMissing()
    }
    do {
      let data = ChampionRotationPredictionModel(
        previousRotationId: previousRotationId,
        champions: predictedChampions,
      )
      try await appDb.saveRotationPrediction(data: data)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }
}

private typealias LoadPredictionLocalData = (
  currentRotation: RegularChampionRotationModel,
  prediction: ChampionRotationPredictionModel,
  champions: [ChampionModel]
)

private typealias GeneratePredictionLocalData = (
  regularRotations: [RegularChampionRotationModel],
  champions: [ChampionModel]
)
