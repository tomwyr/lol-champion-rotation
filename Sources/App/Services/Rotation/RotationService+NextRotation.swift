import Foundation

extension DefaultRotationService {
  func nextRotations(
    nextRotationToken: String, count: Int,
  ) async throws -> [RegularChampionRotation] {
    let localData = try await loadNextRotationLocalData(nextRotationToken, count)
    guard let localData else { return [] }

    let rotationDates = localData.rotations.map(\.observedAt)
    let patchVersions = try await versionService.findVersionsSafe(olderThan: rotationDates)
    let durations = try await getRotationDurations(localData.rotations)

    return try await createNextRotations(localData, patchVersions, durations)
  }

  private func loadNextRotationLocalData(
    _ nextRotationToken: String, _ count: Int,
  ) async throws -> RegularRotationLocalData? {
    guard let nextRotationId = try? idHasher.tokenToId(nextRotationToken) else {
      return nil
    }

    let rotations = try await appDb.findPreviousRegularRotations(
      before: nextRotationId, count: count,
    )
    guard !rotations.isEmpty, let lastRotation = rotations.last else {
      return nil
    }

    let champions = try await appDb.champions()

    let hasPreviousRegularRotation: Bool
    if let rotationId = lastRotation.idString {
      let previousRotation = try await appDb.findPreviousRegularRotation(before: rotationId)
      hasPreviousRegularRotation = previousRotation != nil
    } else {
      hasPreviousRegularRotation = false
    }

    return (rotations, champions, hasPreviousRegularRotation)
  }

  private func createNextRotations(
    _ data: RegularRotationLocalData,
    _ patchVersions: [String?],
    _ durations: [ChampionRotationDuration],
  ) async throws -> [RegularChampionRotation] {
    var result = [RegularChampionRotation]()

    let rotationPairs = data.rotations.indices.map { index in
      (index, data.rotations[index], data.rotations[try: index + 1])
    }

    for (index, current, previous) in rotationPairs {
      let patchVersion = patchVersions[index]
      let duration = durations[index]

      let champions = try createChampions(
        for: current.champions, models: data.champions
      ).sorted { $0.name < $1.name }

      let nextRotationToken =
        // Rotation is `previous` chronologically but `next` from the loading more data point of view.
        if previous != nil || data.hasPreviousRegularRotation {
          try getNextRotationToken(current)
        } else {
          nil as String?
        }

      let rotation = RegularChampionRotation(
        id: current.slug,
        patchVersion: patchVersion,
        duration: duration,
        champions: champions,
        nextRotationToken: nextRotationToken,
        current: false,
      )

      result.append(rotation)
    }

    return result
  }
}

private typealias RegularRotationLocalData = (
  rotations: [RegularChampionRotationModel],
  champions: [ChampionModel],
  hasPreviousRegularRotation: Bool,
)
