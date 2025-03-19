import Foundation

extension DefaultRotationService {
  func nextRotation(nextRotationToken: String) async throws(ChampionRotationError)
    -> RegularChampionRotation?
  {
    let localData = try await loadNextRotationLocalData(nextRotationToken)
    guard let localData else { return nil }
    let nextRotationTime = localData.rotation.observedAt
    let patchVersion = try? await versionService.findVersion(olderThan: nextRotationTime)
    return try await createNextRotation(patchVersion, localData)
  }

  private func loadNextRotationLocalData(_ nextRotationToken: String)
    async throws(ChampionRotationError) -> RegularRotationLocalData?
  {
    let nextRotationId: String
    do {
      nextRotationId = try idHasher.tokenToId(nextRotationToken)
    } catch {
      return nil
    }

    let rotation: RegularChampionRotationModel?
    let champions: [ChampionModel]
    let hasPreviousRegularRotation: Bool
    do {
      rotation = try await appDb.findPreviousRegularRotation(before: nextRotationId)
      champions = try await appDb.champions()
      if let rotationId = rotation?.idString {
        let previousRotation = try await appDb.findPreviousRegularRotation(before: rotationId)
        hasPreviousRegularRotation = previousRotation != nil
      } else {
        hasPreviousRegularRotation = false
      }
    } catch {
      throw .dataOperationFailed(cause: error)
    }
    guard let rotation else {
      return nil
    }
    return (rotation, champions, hasPreviousRegularRotation)
  }

  private func createNextRotation(_ patchVersion: String?, _ data: RegularRotationLocalData)
    async throws(ChampionRotationError) -> RegularChampionRotation
  {
    guard let id = data.rotation.idString else {
      throw .rotationDataMissing
    }

    let champions = try createChampions(
      for: data.rotation.champions, models: data.champions
    ).sorted { $0.name < $1.name }

    let duration = try await getRotationDuration(data.rotation)

    let nextRotationToken =
      // Rotation is `previous` chronologically but `next` from the loading more data point of view.
      if data.hasPreviousRegularRotation {
        try getNextRotationToken(data.rotation)
      } else {
        nil as String?
      }

    return RegularChampionRotation(
      id: id,
      patchVersion: patchVersion,
      duration: duration,
      champions: champions,
      nextRotationToken: nextRotationToken,
      current: false
    )
  }
}

private typealias RegularRotationLocalData = (
  rotation: RegularChampionRotationModel,
  champions: [ChampionModel],
  hasPreviousRegularRotation: Bool
)
