import Foundation

protocol RotationService {
  func currentRotation() async throws(ChampionRotationError) -> ChampionRotation
  func rotation(nextRotationToken: String) async throws(ChampionRotationError)
    -> RegularChampionRotation?
  func refreshRotation() async throws(ChampionRotationError) -> RefreshRotationResult
  func filterRotations(by championName: String) async throws(ChampionRotationError)
    -> FilterRotationsResult
}

struct DefaultRotationService: RotationService {
  let imageUrlProvider: ImageUrlProvider
  let riotApiClient: RiotApiClient
  let appDatabase: AppDatabase
  let versionService: VersionService
  let notificationsService: NotificationsService
  let idHasher: IdHasher

  func getRotationDuration(_ rotation: RegularChampionRotationModel)
    async throws(ChampionRotationError) -> ChampionRotationDuration
  {
    let nextRotationDate = try await getNextRotationDate(rotation)
    let startDate = rotation.observedAt
    guard let endDate = nextRotationDate ?? startDate.adding(1, .weekOfYear) else {
      throw .rotationDurationInvalid
    }
    return ChampionRotationDuration(start: startDate, end: endDate)
  }

  func getNextRotationDate(_ rotation: RegularChampionRotationModel)
    async throws(ChampionRotationError) -> Date?
  {
    do {
      guard let rotationId = try? rotation.requireID().uuidString else {
        return nil
      }
      let nextRotation = try await appDatabase.findNextRegularRotation(after: rotationId)
      return nextRotation?.observedAt
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  func getNextRotationToken(_ rotation: RegularChampionRotationModel)
    throws(ChampionRotationError) -> String?
  {
    let rotationId = rotation.id!.uuidString
    do {
      return try idHasher.idToToken(rotationId)
    } catch {
      throw .tokenHashingFailed(cause: error)
    }
  }
}

enum ChampionRotationError: Error {
  case riotDataUnavailable(cause: Error)
  case championImagesUnavailable(cause: Error)
  case unknownChampion(championKey: String)
  case championImageMissing(championId: String)
  case championDataMissing(championId: String)
  case currentRotationDataMissing
  case rotationDurationInvalid
  case tokenHashingFailed(cause: Error)
  case dataOperationFailed(cause: Error)
}
