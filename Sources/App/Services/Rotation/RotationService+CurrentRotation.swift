import Foundation

extension DefaultRotationService {
  func currentRotation() async throws(ChampionRotationError) -> ChampionRotation {
    let patchVersion = try? await versionService.latestVersion()
    let localData = try await loadCurrentRotationLocalData()
    return try await createChampionRotation(patchVersion, localData)
  }

  private func loadCurrentRotationLocalData() async throws(ChampionRotationError)
    -> CurrentRotationLocalData
  {
    let regularRotation: RegularChampionRotationModel?
    let beginnerRotation: BeginnerChampionRotationModel?
    let champions: [ChampionModel]
    let hasPreviousRegularRotation: Bool
    do {
      regularRotation = try await appDatabase.currentRegularRotation()
      beginnerRotation = try await appDatabase.currentBeginnerRotation()
      champions = try await appDatabase.champions()
      if let rotationId = regularRotation?.idString {
        let previousRotation = try await appDatabase.findPreviousRegularRotation(before: rotationId)
        hasPreviousRegularRotation = previousRotation != nil
      } else {
        hasPreviousRegularRotation = false
      }
    } catch {
      throw .dataOperationFailed(cause: error)
    }
    guard let regularRotation, let beginnerRotation else {
      throw .rotationDataMissing
    }
    return (
      regularRotation,
      beginnerRotation,
      champions,
      hasPreviousRegularRotation
    )
  }

  private func createChampionRotation(_ patchVersion: String?, _ data: CurrentRotationLocalData)
    async throws(ChampionRotationError) -> ChampionRotation
  {
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

    return ChampionRotation(
      patchVersion: patchVersion,
      duration: duration,
      beginnerMaxLevel: beginnerMaxLevel,
      beginnerChampions: beginnerChampions,
      regularChampions: regularChampions,
      nextRotationToken: nextRotationToken
    )
  }
}

private typealias CurrentRotationLocalData = (
  regularRotation: RegularChampionRotationModel,
  beginnerRotation: BeginnerChampionRotationModel,
  champions: [ChampionModel],
  hasPreviousRegularRotation: Bool
)
