import Foundation

protocol RotationService {
  func rotationsOverview() async throws(ChampionRotationError) -> ChampionRotationsOverview
  func currentRegularRotation() async throws(ChampionRotationError) -> ChampionRotationSummary
  func predictRotation() async throws(ChampionRotationError) -> ChampionRotationPrediction
  func rotation(slug: String, userId: String?) async throws(ChampionRotationError)
    -> ChampionRotationDetails?
  func nextRotation(nextRotationToken: String) async throws(ChampionRotationError)
    -> RegularChampionRotation?
  func refreshRotation() async throws(ChampionRotationError) -> RefreshRotationResult
  func filterRotations(by championName: String) async throws(ChampionRotationError)
    -> FilterRotationsResult
  func observedRotations(by userId: String) async throws(ChampionRotationError)
    -> ObservedRotationsData
  func updateObserveRotation(slug: String, by userId: String, observing: Bool)
    async throws(ChampionRotationError) -> Bool?
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
  let slugGenerator: SlugGenerator
  let instant: Instant

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
  case rotationDataMissing(slug: String? = nil)
  case tokenHashingFailed(cause: Error)
  case dataOperationFailed(cause: Error)
  case observedRotationDataInvalid(userId: String)
  case rotationDurationError(cause: RotationDurationError)
  case slugError(cause: SlugGeneratorError)
  case championError(cause: ChampionError)
  case predictionError(cause: RotationForecastError)
}
