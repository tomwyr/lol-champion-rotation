extension DefaultRotationService {
  func currentRegularRotation() async throws -> ChampionRotationSummary {
    let regularRotation = try await appDb.currentRegularRotation()
    let champions = try await appDb.champions()
    guard let regularRotation else {
      throw ChampionRotationError.rotationDataMissing()
    }
    return try await createRotationSummary(regularRotation, champions)
  }

  private func createRotationSummary(
    _ regularRotation: RegularChampionRotationModel,
    _ champions: [ChampionModel],
  ) async throws -> ChampionRotationSummary {
    let id = regularRotation.slug
    let champions = try createChampions(
      for: regularRotation.champions,
      models: champions,
    ).sorted { $0.name < $1.name }
    let duration = try await getRotationDuration(regularRotation)

    return ChampionRotationSummary(
      id: id,
      duration: duration,
      champions: champions,
    )
  }
}
