import Foundation

extension DefaultRotationService {
  func rotation(slug: String, userId: String?) async throws -> ChampionRotationDetails? {
    let localData = try await loadRotationDetailsLocalData(slug, userId)
    guard let localData else { return nil }
    return try await createRotationDetails(slug, localData)
  }

  private func loadRotationDetailsLocalData(
    _ slug: String, _ userId: String?,
  ) async throws -> RotationDetailsLocalData? {
    guard let rotation = try await appDb.regularRotation(slug: slug) else {
      return nil
    }
    let currentRotation = try await appDb.currentRegularRotation()
    let champions = try await appDb.champions()

    var userWatchlists: UserWatchlistsModel?
    if let userId {
      userWatchlists = try await appDb.userWatchlists(userId: userId)
    }

    return (rotation, currentRotation, champions, userWatchlists)
  }

  private func createRotationDetails(
    _ slug: String, _ data: RotationDetailsLocalData,
  ) async throws -> ChampionRotationDetails {
    guard let rotationId = data.rotation.idString else {
      throw ChampionRotationError.rotationDataMissing(slug: slug)
    }

    let champions = try createChampions(
      for: data.rotation.champions, models: data.champions
    ).sorted { $0.name < $1.name }

    let id = data.rotation.slug
    let duration = try await getRotationDuration(data.rotation)
    let current = data.rotation.idString == data.currentRotation?.idString
    let observing = data.userWatchlists?.rotations.contains(rotationId)

    return ChampionRotationDetails(
      id: id,
      duration: duration,
      champions: champions,
      current: current,
      observing: observing
    )
  }
}

private typealias RotationDetailsLocalData = (
  rotation: RegularChampionRotationModel,
  currentRotation: RegularChampionRotationModel?,
  champions: [ChampionModel],
  userWatchlists: UserWatchlistsModel?
)
