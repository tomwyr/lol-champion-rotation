import Fluent
import Vapor

typealias Late<Dependency> = @Sendable (Request) -> Dependency

struct Dependencies {
  var appConfig: AppConfig
  var httpClient: HttpClient
  var fcm: Late<FcmDispatcher>
  var mobileUserGuard: RequestAuthenticatorGuard
  var optionalMobileUserGuard: RequestAuthenticatorGuard

  static func `default`() -> Dependencies {
    .init(
      appConfig: .fromEnvironment(),
      httpClient: NetworkHttpClient(),
      fcm: { req in req.fcm },
      mobileUserGuard: MobileUserGuard(),
      optionalMobileUserGuard: OptionalMobileUserGuard(),
    )
  }

  func rotationService(request: Request) -> RotationService {
    DefaultRotationService(
      imageUrlProvider: imageUrlProvider(request: request),
      riotApiClient: riotApiClient(),
      appDb: appDb(request: request),
      versionService: versionService(request: request),
      notificationsService: notificationsService(request: request),
      idHasher: idHasher(),
      rotationForecast: DefaultRotationForecast(),
      seededSelector: seededSelector(),
      slugGenerator: SlugGenerator(),
    )
  }

  func championsService(request: Request) -> ChampionsService {
    ChampionsService(
      imageUrlProvider: imageUrlProvider(request: request),
      appDb: appDb(request: request),
      seededSelector: seededSelector(),
    )
  }

  func notificationsService(request: Request) -> NotificationsService {
    NotificationsService(
      appDb: appDb(request: request),
      pushNotificationsClient: pushNotificationsClient(request: request),
    )
  }

  func versionService(request: Request) -> VersionService {
    DefaultVersionService(
      versionType: String.self,
      riotApiClient: riotApiClient(),
      appDb: appDb(request: request),
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
      fingerprint: nil,
    )
  }

  func riotApiClient() -> RiotApiClient {
    RiotApiClient(
      http: httpClient,
      apiKey: appConfig.riotApiKey,
    )
  }

  func pushNotificationsClient(request: Request) -> PushNotificationsClient {
    PushNotificationsClient(fcm: fcm(request))
  }

  func appDb(request: Request) -> AppDatabase {
    AppDatabase(
      runner: StartupRetryRunner(database: request.db),
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
