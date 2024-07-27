import Foundation

struct RotationService {
    let riotApiClient: RiotApiClient

    func currentRotation() async throws(CurrentRotationError) -> ChampionRotation {
        let (championRotationsData, championsData) = try await fetchRiotData()

        let championsByKey = championsData.data.values.associateBy(\.key)
        let freeChampionIds = Set(championRotationsData.freeChampionIds)

        func createChampion(id: Int) throws(CurrentRotationError) -> Champion {
            let key = String(id)
            guard let name = championsByKey[key]?.name else {
                throw .unknownChampion(key: key)
            }
            let levelCapped = freeChampionIds.contains(id)
            return Champion(name: name, levelCapped: levelCapped)
        }

        let championIds = Set(
            championRotationsData.freeChampionIdsForNewPlayers
                + championRotationsData.freeChampionIds
        )
        let champions = try championIds.map(createChampion)

        return ChampionRotation(
            playerLevelCap: championRotationsData.maxNewPlayerLevel,
            champions: champions
        )
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
