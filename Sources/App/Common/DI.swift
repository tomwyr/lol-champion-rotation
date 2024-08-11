import Fluent
import Vapor

struct DI {
    static func rotationService(for request: Request, skipCache: Bool = false)
        throws -> RotationService
    {
        RotationService(
            imageUrlProvider: ImageUrlProvider(
                b2ApiClient: B2ApiClient(
                    http: HttpClient(),
                    appKeyId: Environment.get("B2_APP_KEY_ID")!,
                    appKeySecret: Environment.get("B2_APP_KEY_SECRET")!
                ),
                cache: skipCache ? nil : request.cache,
                fingerprint: try Fingerprint(of: request)
            ),
            riotApiClient: RiotApiClient(
                http: HttpClient(),
                apiKey: Environment.get("RIOT_API_KEY")!
            ),
            appDatabase: AppDatabase(database: request.db)
        )
    }
}
