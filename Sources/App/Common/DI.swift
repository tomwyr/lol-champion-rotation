import Vapor

struct DI {
    static var rotationService: RotationService {
        RotationService(
            riotApiClient: RiotApiClient(
                apiKey: Environment.get("RIOT_API_KEY")!
            )
        )
    }
}
