struct RotationRepository {
    let sessionKey: String
    let httpClient: HttpClient

    func currentRotation() async throws(CurrentRotationError) -> ChampionRotation {
        let url = "https://lol-champion-rotation.fly.dev/rotation/current"
        do {
            return try await httpClient.get(
                from: url,
                into: ChampionRotation.self,
                with: ["X-Session-Key": sessionKey]
            )
        } catch {
            throw .unavailable
        }
    }
}
