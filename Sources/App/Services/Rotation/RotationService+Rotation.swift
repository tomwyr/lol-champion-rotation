import Foundation

extension DefaultRotationService {
  func rotation(rotationId: String) async throws(ChampionRotationError) -> RegularChampionRotation?
  {
    let localData = try await loadRegularRotationLocalData(rotationId)
    guard let localData else { return nil }
    let nextRotationTime = localData.rotation.observedAt
    let patchVersion = try? await versionService.findVersion(olderThan: nextRotationTime)
    return try await createRegularRotation(patchVersion, localData)
  }

  private func loadRegularRotationLocalData(_ rotationId: String)
    async throws(ChampionRotationError) -> RegularRotationLocalData?
  {
    let rotation: RegularChampionRotationModel?
    let currentRotation: RegularChampionRotationModel?
    let champions: [ChampionModel]
    do {
      rotation = try await appDatabase.regularRotation(rotationId: rotationId)
      currentRotation = try await appDatabase.currentRegularRotation()
      champions = try await appDatabase.champions()
    } catch {
      throw .dataOperationFailed(cause: error)
    }
    guard let rotation else {
      return nil
    }
    return (rotation, currentRotation, champions)
  }

  private func createRegularRotation(_ patchVersion: String?, _ data: RegularRotationLocalData)
    async throws(ChampionRotationError) -> RegularChampionRotation
  {
    let champions = try createChampions(
      for: data.rotation.champions, models: data.champions
    ).sorted { $0.name < $1.name }

    let duration = try await getRotationDuration(data.rotation)
    let current = data.rotation.id != nil && data.rotation.id == data.currentRotation?.id

    return RegularChampionRotation(
      patchVersion: patchVersion,
      duration: duration,
      champions: champions,
      nextRotationToken: nil,
      current: current
    )
  }
}

private typealias RegularRotationLocalData = (
  rotation: RegularChampionRotationModel,
  currentRotation: RegularChampionRotationModel?,
  champions: [ChampionModel]
)
