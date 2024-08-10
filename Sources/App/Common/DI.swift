import Fluent
import Vapor

struct DI {
    static func rotationService(database: Database, cache: Cache) -> RotationService {
        RotationService(
            imageUrlProvider: ImageUrlProvider(
                b2ApiClient: B2ApiClient(
                    http: HttpClient(),
                    appKeyId: Environment.get("B2_APP_KEY_ID")!,
                    appKeySecret: Environment.get("B2_APP_KEY_SECRET")!
                ),
                cache: cache
            ),
            riotApiClient: RiotApiClient(
                http: HttpClient(),
                apiKey: Environment.get("RIOT_API_KEY")!
            ),
            appDatabase: AppDatabase(database: database)
        )
    }
}
