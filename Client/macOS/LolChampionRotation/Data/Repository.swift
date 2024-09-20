struct RotationRepository {
    let httpClient: HttpClient

    func currentRotation() async throws(CurrentRotationError) -> ChampionRotation {
        let url = "https://lol-champion-rotation.fly.dev/rotation/current"
        do {
            return try await httpClient.get(
                from: url,
                into: ChampionRotation.self
            )
        } catch {
            throw .unavailable
        }
    }
}
