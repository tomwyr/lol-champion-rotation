import Foundation

extension DefaultRotationService {
  func rotationsOverview() async throws -> ChampionRotationsOverview {
    let patchVersion = try? await versionService.latestVersion()
    let localData = try await loadRotationsOverviewLocalData()
    return try await createRotationsOverview(patchVersion, localData)
  }

  private func loadRotationsOverviewLocalData() async throws -> RotationsOverviewLocalData {
    let regularRotation = try await appDb.currentRegularRotation()
    let beginnerRotation = try await appDb.currentBeginnerRotation()
    let champions = try await appDb.champions()

    let hasPreviousRegularRotation: Bool
    if let rotationId = regularRotation?.idString {
      let previousRotation = try await appDb.findPreviousRegularRotation(before: rotationId)
      hasPreviousRegularRotation = previousRotation != nil
    } else {
      hasPreviousRegularRotation = false
    }

    guard let regularRotation, let beginnerRotation else {
      throw ChampionRotationError.rotationDataMissing()
    }

    return (
      regularRotation,
      beginnerRotation,
      champions,
      hasPreviousRegularRotation
    )
  }

  private func createRotationsOverview(
    _ patchVersion: String?, _ data: RotationsOverviewLocalData,
  ) async throws -> ChampionRotationsOverview {
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
