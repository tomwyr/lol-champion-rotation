import Foundation

struct RotationService {
    let imageProvider: ImageProvider
    let riotApiClient: RiotApiClient

    func currentRotation() async throws(CurrentRotationError) -> ChampionRotation {
        let (championRotationsData, championsData) = try await fetchRiotData()

        let championsByKey = championsData.data.values.associateBy(\.key)
        let freeChampionIds = Set(championRotationsData.freeChampionIds)

        func createChampion(id: Int) throws(CurrentRotationError) -> Champion {
            let key = String(id)
            guard let champion = championsByKey[key] else {
                throw .unknownChampion(key: key)
            }
            let levelCapped = freeChampionIds.contains(id)
            let imageUrl = imageProvider.champion(with: champion.id)
            return Champion(name: champion.name, levelCapped: levelCapped, imageUrl: imageUrl)
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
