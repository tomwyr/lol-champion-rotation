import Fluent
import Vapor

struct DI {
    static func rotationService(database: Database) -> RotationService {
        RotationService(
            imageProvider: ImageProvider(
                baseUrl: Environment.get("APP_BASE_URL")!
            ),
            riotApiClient: RiotApiClient(
                apiKey: Environment.get("RIOT_API_KEY")!
            ),
            appDatabase: AppDatabase(database: database)
        )
    }
}
