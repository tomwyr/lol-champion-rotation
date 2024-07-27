struct DI {
    static var rotationService: RotationService {
        RotationService(
            riotApiClient: RiotApiClient(
                apiKey: "RGAPI-2faef0c2-c00a-417d-bd87-6dfdb9183629"
            )
        )
    }
}
