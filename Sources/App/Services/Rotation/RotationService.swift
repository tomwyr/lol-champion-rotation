import Foundation

protocol RotationService {
  func currentRotation() async throws(ChampionRotationError) -> ChampionRotation
  func predictRotation() async throws(ChampionRotationError) -> PredictedChampionRotation
  func rotation(rotationId: String) async throws(ChampionRotationError) -> RegularChampionRotation?
  func nextRotation(nextRotationToken: String) async throws(ChampionRotationError)
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
  let rotationForecast: RotationForecast

  typealias OutError = ChampionRotationError

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
  case unknownChampion(championKey: String)
  case currentRotationDataMissing
  case tokenHashingFailed(cause: Error)
  case dataOperationFailed(cause: Error)
  case rotationDurationError(cause: RotationDurationError)
  case championError(cause: ChampionError)
  case predictionError(cause: RotationForecastError)
}
