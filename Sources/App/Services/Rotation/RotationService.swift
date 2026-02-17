import Foundation

protocol RotationService {
  func rotationsOverview() async throws -> ChampionRotationsOverview
  func currentRegularRotation() async throws -> ChampionRotationSummary
  func predictRotation() async throws -> ChampionRotationPrediction
  func rotation(slug: String, userId: String?) async throws -> ChampionRotationDetails?
  func nextRotation(nextRotationToken: String) async throws -> RegularChampionRotation?
  func refreshRotation() async throws -> RefreshRotationResult
  func filterRotations(by championName: String) async throws -> FilterRotationsResult
  func observedRotations(by userId: String) async throws -> ObservedRotationsData
  func updateObserveRotation(slug: String, by userId: String, observing: Bool) async throws -> Bool?
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

  func getNextRotationToken(_ rotation: RegularChampionRotationModel) throws -> String? {
    let rotationId = rotation.id!.uuidString
    return try idHasher.idToToken(rotationId)
  }
}

enum ChampionRotationError: Error {
  case unknownChampion(championKey: String)
  case rotationDataMissing(slug: String? = nil)
}
