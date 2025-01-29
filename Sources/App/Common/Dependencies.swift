import Fluent
import Vapor

struct Dependencies {
  var appConfig: AppConfig
  var httpClient: HttpClient

  static func `default`() -> Dependencies {
    .init(
      appConfig: .fromEnvironment(),
      httpClient: NetworkHttpClient()
    )
  }

  func rotationService(request: Request) -> RotationService {
    DefaultRotationService(
      imageUrlProvider: imageUrlProvider(request: request),
      riotApiClient: riotApiClient(),
      appDatabase: appDatabase(request: request),
      versionService: versionService(request: request),
      notificationsService: notificationsService(request: request),
      tokenMapper: tokenMapper()
    )
  }

  func notificationsService(request: Request) -> NotificationsService {
    NotificationsService(
      appDatabase: appDatabase(request: request),
      pushNotificationsClient: pushNotificationsClient(request: request)
    )
  }

  func versionService(request: Request) -> VersionService {
    DefaultVersionService(
      versionType: String.self,
      riotApiClient: riotApiClient(),
      appDatabase: appDatabase(request: request)
    )
  }

  func imageUrlProvider(request: Request) -> ImageUrlProvider {
    ImageUrlProvider(
      b2ApiClient: B2ApiClient(
        http: httpClient,
        appKeyId: appConfig.b2AppKeyId,
        appKeySecret: appConfig.b2AppKeySecret
      ),
      cache: request.cache,
      fingerprint: nil
    )
  }

  func riotApiClient() -> RiotApiClient {
    RiotApiClient(
      http: httpClient,
      apiKey: appConfig.riotApiKey
    )
  }

  func pushNotificationsClient(request: Request) -> PushNotificationsClient {
    PushNotificationsClient(
      fcm: request.fcm
    )
  }

  func appDatabase(request: Request) -> AppDatabase {
    AppDatabase(
      runner: StartupRetryRunner(database: request.db)
    )
  }

  func tokenMapper() -> TokenMapper {
    TokenMapper()
  }
}
