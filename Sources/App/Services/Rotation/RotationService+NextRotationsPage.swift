import Foundation

extension RotationService {
  func nextRotationsPage(
    page: Int, count: Int?, historical: Bool?,
  ) async throws -> RegularChampionRotationsPage? {
    try await nextRotationsPage(page: page, count: count ?? 5, historical: historical ?? false)
  }
}

extension DefaultRotationService {
  func nextRotationsPage(
    page: Int, count: Int, historical: Bool,
  ) async throws -> RegularChampionRotationsPage? {
    let localData = try await loadLocalData(page, count, historical)
    guard let localData else { return nil }

    let rotationDates = localData.rotations.map(\.observedAt)
    let patchVersions = try await versionService.findVersionsSafe(olderThan: rotationDates)
    let durations = try await getRotationDurations(localData.rotations)
    let entries = try await createNextRotations(localData, patchVersions, durations)

    return RegularChampionRotationsPage(entries: entries, hasNext: localData.hasNext)
  }

  private func loadLocalData(
    _ page: Int, _ count: Int, _ historical: Bool,
  ) async throws -> NextRotationsPageLocalData? {
    let rotations = try await appDb.findPreviousRegularRotations(
      page: page, count: count, historical: historical,
    )
    guard !rotations.isEmpty, let lastRotation = rotations.last else {
      return nil
    }

    let champions = try await appDb.champions()

    guard let lastRotationId = lastRotation.idString else { return nil }
    let nextRotationAfterLast = try await appDb.findPreviousRegularRotation(before: lastRotationId)
    let hasNext = nextRotationAfterLast != nil

    return (rotations, champions, hasNext)
  }

  private func createNextRotations(
    _ data: NextRotationsPageLocalData,
    _ patchVersions: [String?],
    _ durations: [ChampionRotationDuration],
  ) async throws -> [RegularChampionRotation] {
    var result = [RegularChampionRotation]()

    for (index, rotation) in data.rotations.indexed() {
      let patchVersion = patchVersions[index]
      let duration = durations[index]

      let champions = try createChampions(
        for: rotation.champions, models: data.champions
      ).sorted { $0.name < $1.name }

      let rotation = RegularChampionRotation(
        id: rotation.slug,
        patchVersion: patchVersion,
        duration: duration,
        champions: champions,
        nextRotationToken: nil,
        current: false,
      )

      result.append(rotation)
    }

    return result
  }
}

private typealias NextRotationsPageLocalData = (
  rotations: [RegularChampionRotationModel],
  champions: [ChampionModel],
  hasNext: Bool,
)
