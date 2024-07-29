import Vapor

struct DI {
    static var rotationService: RotationService {
        RotationService(
            imageProvider: ImageProvider(
                baseUrl: Environment.get("APP_BASE_URL")!
            ),
            riotApiClient: RiotApiClient(
                apiKey: Environment.get("RIOT_API_KEY")!
            )
        )
    }
}
