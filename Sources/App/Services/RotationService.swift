import Foundation

struct RotationService {
    let imageUrlProvider: ImageUrlProvider
    let riotApiClient: RiotApiClient
    let appDatabase: AppDatabase

    func currentRotation() async throws(CurrentRotationError) -> ChampionRotation {
        let data = try await fetchRiotData()
        let rotation = try await createRotation(riotData: data)
        _ = try await saveRotationIfChanged(rotation)
        return rotation
    }

    func refreshRotation() async throws(CurrentRotationError) -> RefreshRotationResult {
        let data = try await fetchRiotData()
        let rotation = try await createRotation(riotData: data)
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

    private func createRotation(riotData: CurrentRotationRiotData)
        async throws(CurrentRotationError) -> ChampionRotation
    {
        let imageUrlsByChampionId = try await championsByKey(riotData: riotData)
        return try createRotation(
            riotData: riotData,
            imageUrlsByChampionId: imageUrlsByChampionId
        )
    }
}

extension RotationService {
    private func championsByKey(riotData: CurrentRotationRiotData)
        async throws(CurrentRotationError) -> [String: String]
    {
        do {
            let championKeys = Array(riotData.champions.data.keys)
            let imageUrls = try await imageUrlProvider.champions(with: championKeys)
            return Dictionary(uniqueKeysWithValues: zip(championKeys, imageUrls))
        } catch {
            throw .championImagesUnavailable(cause: error)
        }
    }
}

extension RotationService {
    private func createRotation(
        riotData: CurrentRotationRiotData,
        imageUrlsByChampionId: [String: String]
    ) throws(CurrentRotationError) -> ChampionRotation {
        let playerLevelCap = riotData.championRotations.maxNewPlayerLevel
        let championsByKey = riotData.champions.data.values.associateBy(\.key)
        let freeChampionKeys = Set(riotData.championRotations.freeChampionIds).map { String($0) }
        let allChampionKeys = Set(
            riotData.championRotations.freeChampionIdsForNewPlayers
                + riotData.championRotations.freeChampionIds
        ).map { String($0) }

        let championData = try allChampionKeys.map { key throws(CurrentRotationError) in
            guard let champion = championsByKey[key] else {
                throw .unknownChampion(championKey: key)
            }
            return champion
        }

        let champions = try championData.map { data throws(CurrentRotationError) in
            let levelCapped = freeChampionKeys.contains(data.key)
            guard let imageUrl = imageUrlsByChampionId[data.id] else {
                throw .championImageMissing(championId: data.id)
            }

            return Champion(
                id: data.id,
                name: data.name,
                levelCapped: levelCapped,
                imageUrl: imageUrl
            )
        }.sorted { $0.id < $1.id }

        return ChampionRotation(playerLevelCap: playerLevelCap, champions: champions)
    }
}

extension RotationService {
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
    case championImagesUnavailable(cause: Error)
    case unknownChampion(championKey: String)
    case championImageMissing(championId: String)
    case dataOperationFailed(cause: Error)
}
