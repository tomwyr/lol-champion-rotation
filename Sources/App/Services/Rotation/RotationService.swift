import Foundation

protocol RotationService {
  func currentRotation() async throws(ChampionRotationError) -> CurrentChampionRotation
  func currentRegularRotation() async throws(ChampionRotationError) -> ChampionRotationSummary
  func predictRotation() async throws(ChampionRotationError) -> ChampionRotationPrediction
  func rotation(rotationId: String, userId: String?) async throws(ChampionRotationError)
    -> ChampionRotationDetails?
  func nextRotation(nextRotationToken: String) async throws(ChampionRotationError)
    -> RegularChampionRotation?
  func refreshRotation() async throws(ChampionRotationError) -> RefreshRotationResult
  func filterRotations(by championName: String) async throws(ChampionRotationError)
    -> FilterRotationsResult
  func observedRotations(by userId: String) async throws(ChampionRotationError)
    -> ObservedRotationsData
  func updateObserveRotation(rotationId: String, by userId: String, observing: Bool)
    async throws(ChampionRotationError)
}

struct DefaultRotationService: RotationService {
  let imageUrlProvider: ImageUrlProvider
  let riotApiClient: RiotApiClient
  let appDb: AppDatabase
  let versionService: VersionService
  let notificationsService: NotificationsService
  let idHasher: IdHasher
  let rotationForecast: RotationForecast
  let seededSelector: SeededSelector

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
  case rotationDataMissing
  case tokenHashingFailed(cause: Error)
  case dataOperationFailed(cause: Error)
  case observedRotationDataInvalid(userId: String)
  case rotationDurationError(cause: RotationDurationError)
  case championError(cause: ChampionError)
  case predictionError(cause: RotationForecastError)
}
