import Foundation

struct RotationService {
    let imageUrlProvider: ImageUrlProvider
    let riotApiClient: RiotApiClient
    let appDatabase: AppDatabase

    func currentRotation() async throws(CurrentRotationError) -> ChampionRotation {
        let data = try await fetchRiotData()
        let rotation = try await createRotation(riotData: data)
        _ = try await appDatabase.saveRotationIfChanged(rotation)
        return rotation
    }

    func refreshRotation() async throws(CurrentRotationError) -> RefreshRotationResult {
        let data = try await fetchRiotData()
        let rotation = try await createRotation(riotData: data)
        let rotationChanged = try await appDatabase.saveRotationIfChanged(rotation)
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

    private func createRotation(riotData: CurrentRotationRiotData)
        async throws(CurrentRotationError) -> ChampionRotation
    {
        let imageUrlsByKey = try await imageUrlProvider.championsByKey(riotData: riotData)
        return try ChampionRotation(riotData: riotData, imageUrlsByKey: imageUrlsByKey)
    }
}

extension ImageUrlProvider {
    fileprivate func championsByKey(riotData: CurrentRotationRiotData)
        async throws(CurrentRotationError) -> [String: String]
    {
        do {
            let championKeys = Array(riotData.champions.data.keys)
            let imageUrls = try await champions(with: championKeys)
            return Dictionary(uniqueKeysWithValues: zip(championKeys, imageUrls))
        } catch {
            throw .imageUrlsUnavailable(cause: error)
        }
    }
}

extension ChampionRotation {
    fileprivate init(riotData: CurrentRotationRiotData, imageUrlsByKey: [String: String])
        throws(CurrentRotationError)
    {
        let playerLevelCap = riotData.championRotations.maxNewPlayerLevel
        let championsByKey = riotData.champions.data.values.associateBy(\.key)
        let freeChampionIds = Set(riotData.championRotations.freeChampionIds).map { String($0) }
        let championIds = Set(
            riotData.championRotations.freeChampionIdsForNewPlayers
                + riotData.championRotations.freeChampionIds
        ).map { String($0) }

        let championData = try championIds.map { id throws(CurrentRotationError) in
            let key = String(id)
            guard let champion = championsByKey[key] else {
                throw .unknownChampion(key: key)
            }
            return champion
        }

        let champions = try championData.map { data throws(CurrentRotationError) in
            let levelCapped = freeChampionIds.contains(data.id)
            guard let imageUrl = imageUrlsByKey[data.key] else {
                throw .unknownChampion(key: data.key)
            }

            return Champion(
                id: data.id,
                name: data.name,
                levelCapped: levelCapped,
                imageUrl: imageUrl
            )
        }

        self.playerLevelCap = playerLevelCap
        self.champions = champions
    }
}

extension AppDatabase {
    fileprivate func saveRotationIfChanged(_ rotation: ChampionRotation)
        async throws(CurrentRotationError) -> Bool
    {
        do {
            let championIds = rotation.champions.map(\.id)
            let mostRecentRotation = try await mostRecentChampionRotation()

            let rotationChanged: Bool
            if let lastChampionIds = mostRecentRotation?.championIds {
                rotationChanged = Set(lastChampionIds) != Set(championIds)
            } else {
                rotationChanged = true
            }

            let data = ChampionRotationModel(championIds: championIds)
            try await addChampionRotation(data: data)

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
    case imageUrlsUnavailable(cause: Error)
    case unknownChampion(key: String)
    case dataOperationFailed(cause: Error)
}
