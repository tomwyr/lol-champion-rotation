import Foundation

extension DefaultRotationService {
  func rotation(rotationId: String, userId: String?) async throws(ChampionRotationError)
    -> ChampionRotationDetails?
  {
    let localData = try await loadRotationDetailsLocalData(rotationId, userId)
    guard let localData else { return nil }
    return try await createRotationDetails(rotationId, localData)
  }

  private func loadRotationDetailsLocalData(_ rotationId: String, _ userId: String?)
    async throws(ChampionRotationError) -> RotationDetailsLocalData?
  {
    let rotation: RegularChampionRotationModel?
    let currentRotation: RegularChampionRotationModel?
    let champions: [ChampionModel]
    var userWatchlists: UserWatchlistsModel?
    do {
      rotation = try await appDatabase.regularRotation(rotationId: rotationId)
      currentRotation = try await appDatabase.currentRegularRotation()
      champions = try await appDatabase.champions()
      if let userId {
        userWatchlists = try await appDatabase.userWatchlists(userId: userId) {
          .init(userId: userId)
        }
      }
    } catch {
      throw .dataOperationFailed(cause: error)
    }
    guard let rotation else {
      return nil
    }
    return (rotation, currentRotation, champions, userWatchlists)
  }

  private func createRotationDetails(_ rotationId: String, _ data: RotationDetailsLocalData)
    async throws(ChampionRotationError) -> ChampionRotationDetails
  {
    let champions = try createChampions(
      for: data.rotation.champions, models: data.champions
    ).sorted { $0.name < $1.name }

    let duration = try await getRotationDuration(data.rotation)
    let current = data.rotation.id != nil && data.rotation.id == data.currentRotation?.id
    let observing = data.userWatchlists?.rotations.contains(rotationId)

    return ChampionRotationDetails(
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
