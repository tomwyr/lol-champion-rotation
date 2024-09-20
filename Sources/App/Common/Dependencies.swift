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
        RotationService(
            imageUrlProvider: ImageUrlProvider(
                b2ApiClient: B2ApiClient(
                    http: httpClient,
                    appKeyId: appConfig.b2AppKeyId,
                    appKeySecret: appConfig.b2AppKeySecret
                ),
                cache: request.cache,
                fingerprint: nil
            ),
            riotApiClient: RiotApiClient(
                http: httpClient,
                apiKey: appConfig.riotApiKey
            ),
            appDatabase: AppDatabase(database: request.db)
        )
    }
}
