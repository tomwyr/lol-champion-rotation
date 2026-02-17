import Foundation

extension DefaultRotationService {
  func nextRotation(nextRotationToken: String) async throws -> RegularChampionRotation? {
    let localData = try await loadNextRotationLocalData(nextRotationToken)
    guard let localData else { return nil }
    let nextRotationTime = localData.rotation.observedAt
    let patchVersion = try? await versionService.findVersion(olderThan: nextRotationTime)
    return try await createNextRotation(patchVersion, localData)
  }

  private func loadNextRotationLocalData(
    _ nextRotationToken: String,
  ) async throws -> RegularRotationLocalData? {
    let nextRotationId: String
    do {
      nextRotationId = try idHasher.tokenToId(nextRotationToken)
    } catch {
      return nil
    }

    guard let rotation = try await appDb.findPreviousRegularRotation(before: nextRotationId) else {
      return nil
    }
    let champions = try await appDb.champions()

    let hasPreviousRegularRotation: Bool
    if let rotationId = rotation.idString {
      let previousRotation = try await appDb.findPreviousRegularRotation(before: rotationId)
      hasPreviousRegularRotation = previousRotation != nil
    } else {
      hasPreviousRegularRotation = false
    }

    return (rotation, champions, hasPreviousRegularRotation)
  }

  private func createNextRotation(
    _ patchVersion: String?,
    _ data: RegularRotationLocalData,
  ) async throws -> RegularChampionRotation {
    let id = data.rotation.slug
    let duration = try await getRotationDuration(data.rotation)
    let champions = try createChampions(
      for: data.rotation.champions, models: data.champions
    ).sorted { $0.name < $1.name }

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
