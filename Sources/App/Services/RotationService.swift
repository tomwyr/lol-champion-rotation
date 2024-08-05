import Foundation

struct RotationService {
    let imageProvider: ImageProvider
    let riotApiClient: RiotApiClient
    let appDatabase: AppDatabase

    func currentRotation() async throws(CurrentRotationError) -> ChampionRotation {
        let data = try await fetchRiotData()
        let rotation = try await createRotation(from: data)
        _ = try await saveRotationIfChanged(rotation)
        return rotation
    }

    func refreshRotation() async throws(CurrentRotationError) -> RefreshRotationResult {
        let data = try await fetchRiotData()
        let rotation = try await createRotation(from: data)
        let rotationChanged = try await saveRotationIfChanged(rotation)
        return RefreshRotationResult(rotationChanged: rotationChanged)
    }

    private func fetchRiotData() async throws(CurrentRotationError) -> CurrentRotationRiotData {
        do {
            let championRotations = try await riotApiClient.championRotations()
            let champions = try await riotApiClient.champions()
            return (championRotations, champions)
        } catch {
            throw .riotDataUnavailable(cause: error)
        }
    }

    private func createRotation(from data: CurrentRotationRiotData)
        async throws(CurrentRotationError) -> ChampionRotation
    {
        let playerLevelCap = data.championRotations.maxNewPlayerLevel

        let championsByKey = data.champions.data.values.associateBy(\.key)
        let freeChampionIds = Set(data.championRotations.freeChampionIds)
        let championIds = Set(
            data.championRotations.freeChampionIdsForNewPlayers
                + data.championRotations.freeChampionIds
        )

        let champions = try championIds.map { id throws(CurrentRotationError) in
            let key = String(id)
            guard let champion = championsByKey[key] else {
                throw .unknownChampion(key: key)
            }
            let levelCapped = freeChampionIds.contains(id)
            let imageUrl = imageProvider.champion(with: champion.id)

            return Champion(
                id: champion.id,
                name: champion.name,
                levelCapped: levelCapped,
                imageUrl: imageUrl
            )
        }

        return ChampionRotation(
            playerLevelCap: playerLevelCap,
            champions: champions
        )
    }

    private func saveRotationIfChanged(_ rotation: ChampionRotation)
        async throws(CurrentRotationError) -> Bool
    {
        do {
            let championIds = rotation.champions.map(\.id)
            let mostRecentRotation = try await appDatabase.mostRecentChampionRotation()

            let rotationChanged: Bool
            if let lastChampionIds = mostRecentRotation?.championIds {
                rotationChanged = Set(lastChampionIds) != Set(championIds)
            } else {
                rotationChanged = true
            }

            let data = ChampionRotationModel(championIds: championIds)
            try await appDatabase.addChampionRotation(data: data)

            return rotationChanged
        } catch {
            throw .dataOperationFailed(cause: error)
        }
    }
}

private typealias CurrentRotationRiotData = (
    championRotations: ChampionRotationsData,
    champions: ChampionsData
)

enum CurrentRotationError: Error {
    case riotDataUnavailable(cause: Error)
    case unknownChampion(key: String)
    case dataOperationFailed(cause: Error)
}
