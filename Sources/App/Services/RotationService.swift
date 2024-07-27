struct RotationService {
    let riotApiClient: RiotApiClient

    func currentRotation() async throws(CurrentRotationError) -> ChampionRotation {
        let (championRotationsData, championsData) = try await fetchRiotData()

        let championsByKey = championsData.data.values.associateBy(\.key)
        let champions = try championRotationsData.freeChampionIds.map {
            id throws(CurrentRotationError) in
            let key = String(id)
            guard let name = championsByKey[key]?.name else {
                throw .unknownChampion(key: key)
            }
            return Champion(name: name)
        }

        return ChampionRotation(champions: champions)
    }

    private func fetchRiotData() async throws(CurrentRotationError) -> (
        ChampionRotationsData, ChampionsData
    ) {
        do {
            let championRotations = try await riotApiClient.championRotations()
            let champions = try await riotApiClient.champions()
            return (championRotations, champions)
        } catch {
            throw .riotDataUnavailable(cause: error)
        }
    }
}

enum CurrentRotationError: Error {
    case riotDataUnavailable(cause: Error)
    case unknownChampion(key: String)
}
