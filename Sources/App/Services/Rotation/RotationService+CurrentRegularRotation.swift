extension DefaultRotationService {
  func currentRegularRotation() async throws(ChampionRotationError) -> ChampionRotationSummary {
    let localData = try await loadRotationLocalData()
    return try await createRotationSummary(localData)
  }

  private func loadRotationLocalData() async throws(ChampionRotationError)
    -> CurrentRegularRotationLocalData
  {
    let regularRotation: RegularChampionRotationModel?
    let champions: [ChampionModel]
    do {
      regularRotation = try await appDb.currentRegularRotation()
      champions = try await appDb.champions()
    } catch {
      throw .dataOperationFailed(cause: error)
    }
    guard let regularRotation else {
      throw .rotationDataMissing
    }
    return (regularRotation, champions)
  }

  private func createRotationSummary(_ data: CurrentRegularRotationLocalData)
    async throws(ChampionRotationError) -> ChampionRotationSummary
  {
    guard let id = data.regularRotation.idString else {
      throw .rotationDataMissing
    }
    let champions = try createChampions(
      for: data.regularRotation.champions, models: data.champions
    ).sorted { $0.name < $1.name }
    let duration = try await getRotationDuration(data.regularRotation)

    return ChampionRotationSummary(
      id: id,
      duration: duration,
      champions: champions,
    )
  }
}

private typealias CurrentRegularRotationLocalData = (
  regularRotation: RegularChampionRotationModel,
  champions: [ChampionModel]
)
