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
        let championsByKey = riotData.champions.data.values.associateBy(\.key)
        let beginnerMaxLevel = riotData.championRotations.maxNewPlayerLevel
        let beginnerChampionIds = riotData.championRotations.freeChampionIdsForNewPlayers
            .map { String($0) }
        let regularChampionIds = riotData.championRotations.freeChampionIds
            .map { String($0) }

        func createChampion(key: String) throws(CurrentRotationError) -> Champion {
            guard let data = championsByKey[key] else {
                throw .unknownChampion(championKey: key)
            }
            guard let imageUrl = imageUrlsByChampionId[data.id] else {
                throw .championImageMissing(championId: data.id)
            }
            return Champion(
                id: data.id,
                name: data.name,
                imageUrl: imageUrl
            )
        }

        let beginnerChampions = try beginnerChampionIds.map(createChampion).sorted { $0.id < $1.id }
        let regularChampions = try regularChampionIds.map(createChampion).sorted { $0.id < $1.id }

        return ChampionRotation(
            beginnerMaxLevel: beginnerMaxLevel,
            beginnerChampions: beginnerChampions,
            regularChampions: regularChampions
        )
    }
}

extension RotationService {
    private func saveRotationIfChanged(_ rotation: ChampionRotation)
        async throws(CurrentRotationError) -> Bool
    {
        do {
            let newestSnapshot = rotation.toSnapshot()
            let mostRecentSnapshot = try await appDatabase.mostRecentChampionRotation()?
                .toSnapshot()

            if let mostRecentSnapshot, newestSnapshot.same(as: mostRecentSnapshot) {
                return false
            }

            let data = ChampionRotationModel(snapshot: newestSnapshot)
            try await appDatabase.addChampionRotation(data: data)

            return true
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
