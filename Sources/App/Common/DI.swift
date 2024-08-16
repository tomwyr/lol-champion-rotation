import Fluent
import Vapor

struct DI {
    static func rotationService(for request: Request, fingerprint: Fingerprint?)
        throws -> RotationService
    {
        RotationService(
            imageUrlProvider: ImageUrlProvider(
                b2ApiClient: B2ApiClient(
                    http: HttpClient(),
                    appKeyId: Environment.get("B2_APP_KEY_ID")!,
                    appKeySecret: Environment.get("B2_APP_KEY_SECRET")!
                ),
                cache: request.cache,
                fingerprint: fingerprint
            ),
            riotApiClient: RiotApiClient(
                http: HttpClient(),
                apiKey: Environment.get("RIOT_API_KEY")!
            ),
            appDatabase: AppDatabase(database: request.db)
        )
    }
}
