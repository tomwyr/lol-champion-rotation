import Fluent
import Vapor

typealias Late<Dependency> = @Sendable (Request) -> Dependency

struct Dependencies: Sendable {
  var appConfig: AppConfig
  var httpClient: HttpClient
  var graphQLClient: GraphQLClient
  var fcm: Late<FcmDispatcher>
  var mobileUserGuard: RequestAuthenticatorGuard
  var optionalMobileUserGuard: RequestAuthenticatorGuard
  var rotationForecast: RotationForecast
  var instant: Instant

  static func `default`() -> Dependencies {
    .init(
      appConfig: .fromEnvironment(),
      httpClient: NetworkHttpClient(),
      graphQLClient: NetworkGraphQLClient(http: NetworkHttpClient()),
      fcm: { req in req.fcm },
      mobileUserGuard: MobileUserGuard(),
      optionalMobileUserGuard: OptionalMobileUserGuard(),
      rotationForecast: DefaultRotationForecast(),
      instant: .system,
    )
  }

  func rotationService(request: Request) -> RotationService {
    DefaultRotationService(
      logger: request.logger,
      imageUrlProvider: imageUrlProvider(request: request),
      riotApiClient: riotApiClient(),
      appDb: appDb(request: request),
      versionService: versionService(request: request),
      notificationsService: notificationsService(request: request),
      idHasher: idHasher(),
      rotationForecast: rotationForecast,
      seededSelector: seededSelector(),
      slugGenerator: SlugGenerator(),
      instant: instant,
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

  func feedbackService(request: Request) -> FeedbackService {
    FeedbackService(
      linearClient: LinearClient(
        gql: graphQLClient,
        accessToken: appConfig.linearAccessToken,
      ),
      linearTeamId: appConfig.linearTeamId,
      linearFeedbackStateId: appConfig.linearFeedbackStateId,
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
      runner: StartupRetryRunner(
        database: request.db,
        logger: request.logger,
      ),
      instant: instant,
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
