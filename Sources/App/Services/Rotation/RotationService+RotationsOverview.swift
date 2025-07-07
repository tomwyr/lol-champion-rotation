import Foundation

extension DefaultRotationService {
  func rotationsOverview() async throws(ChampionRotationError) -> ChampionRotationsOverview {
    let patchVersion = try? await versionService.latestVersion()
    let localData = try await loadRotationsOverviewLocalData()
    return try await createRotationsOverview(patchVersion, localData)
  }

  private func loadRotationsOverviewLocalData() async throws(ChampionRotationError)
    -> RotationsOverviewLocalData
  {
    let regularRotation: RegularChampionRotationModel?
    let beginnerRotation: BeginnerChampionRotationModel?
    let champions: [ChampionModel]
    let hasPreviousRegularRotation: Bool
    do {
      regularRotation = try await appDb.currentRegularRotation()
      beginnerRotation = try await appDb.currentBeginnerRotation()
      champions = try await appDb.champions()
      if let rotationId = regularRotation?.idString {
        let previousRotation = try await appDb.findPreviousRegularRotation(before: rotationId)
        hasPreviousRegularRotation = previousRotation != nil
      } else {
        hasPreviousRegularRotation = false
      }
    } catch {
      throw .dataOperationFailed(cause: error)
    }
    guard let regularRotation, let beginnerRotation else {
      throw .rotationDataMissing()
    }
    return (
      regularRotation,
      beginnerRotation,
      champions,
      hasPreviousRegularRotation
    )
  }

  private func createRotationsOverview(_ patchVersion: String?, _ data: RotationsOverviewLocalData)
    async throws(ChampionRotationError) -> ChampionRotationsOverview
  {
    let id = data.regularRotation.slug
    let beginnerMaxLevel = data.beginnerRotation.maxLevel
    let beginnerChampions = try createChampions(
      for: data.beginnerRotation.champions, models: data.champions
    ).sorted { $0.name < $1.name }
    let regularChampions = try createChampions(
      for: data.regularRotation.champions, models: data.champions
    ).sorted { $0.name < $1.name }

    let duration = try await getRotationDuration(data.regularRotation)

    let nextRotationToken =
      // Rotation is `previous` chronologically but `next` from the loading more data point of view.
      if data.hasPreviousRegularRotation {
        try getNextRotationToken(data.regularRotation)
      } else {
        nil as String?
      }

    return ChampionRotationsOverview(
      id: id,
      patchVersion: patchVersion,
      duration: duration,
      beginnerMaxLevel: beginnerMaxLevel,
      beginnerChampions: beginnerChampions,
      regularChampions: regularChampions,
      nextRotationToken: nextRotationToken
    )
  }
}

private typealias RotationsOverviewLocalData = (
  regularRotation: RegularChampionRotationModel,
  beginnerRotation: BeginnerChampionRotationModel,
  champions: [ChampionModel],
  hasPreviousRegularRotation: Bool
)
