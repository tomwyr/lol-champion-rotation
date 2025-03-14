import Fluent
import Vapor

struct Dependencies {
  var appConfig: AppConfig
  var httpClient: HttpClient
  var mobileUserGuard: RequestAuthenticatorGuard

  static func `default`() -> Dependencies {
    .init(
      appConfig: .fromEnvironment(),
      httpClient: NetworkHttpClient(),
      mobileUserGuard: MobileUserGuard()
    )
  }

  func rotationService(request: Request) -> RotationService {
    DefaultRotationService(
      imageUrlProvider: imageUrlProvider(request: request),
      riotApiClient: riotApiClient(),
      appDatabase: appDatabase(request: request),
      versionService: versionService(request: request),
      notificationsService: notificationsService(request: request),
      idHasher: idHasher(),
      rotationForecast: DefaultRotationForecast(),
      seededSelector: seededSelector()
    )
  }

  func championsService(request: Request) -> ChampionsService {
    ChampionsService(
      imageUrlProvider: imageUrlProvider(request: request),
      appDatabase: appDatabase(request: request),
      seededSelector: seededSelector()
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

  func idHasher() -> IdHasher {
    Base62IdHasher(
      seed: appConfig.idHasherSeed
    )
  }

  func seededSelector() -> SeededSelector {
    SeededSelector()
  }
}
