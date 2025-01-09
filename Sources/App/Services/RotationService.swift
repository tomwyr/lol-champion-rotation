import Foundation

protocol RotationService {
  func currentRotation() async throws(CurrentRotationError) -> ChampionRotation
  func refreshRotation() async throws(CurrentRotationError) -> RefreshRotationResult
}

struct DefaultRotationService: RotationService {
  let imageUrlProvider: ImageUrlProvider
  let riotApiClient: RiotApiClient
  let appDatabase: AppDatabase
  let versionService: VersionService
  let notificationsService: NotificationsService

  func currentRotation() async throws(CurrentRotationError) -> ChampionRotation {
    let patchVersion = try? await versionService.latestVersion()
    let localData = try await loadRotationLocalData()
    let imageUrlsByChampionId = try await fetchImageUrls(localData)
    return try createRotation(patchVersion, localData, imageUrlsByChampionId)
  }

  func refreshRotation() async throws(CurrentRotationError) -> RefreshRotationResult {
    let riotData = try await fetchRotationRiotData()
    let rotation = try createRotationModel(riotData)
    let rotationChanged = try await saveRotationIfChanged(rotation)
    try await saveChampionsData(riotData)
    if rotationChanged {
      try? await notificationsService.notifyRotationChanged()
    }
    return RefreshRotationResult(rotationChanged: rotationChanged)
  }
}

extension DefaultRotationService {
  private func fetchRotationRiotData() async throws(CurrentRotationError)
    -> CurrentRotationRiotData
  {
    do {
      let championRotations = try await riotApiClient.championRotations()
      let version = try await versionService.latestVersion()
      let champions = try await riotApiClient.champions(version: version)
      return CurrentRotationRiotData(championRotations, champions)
    } catch {
      throw .riotDataUnavailable(cause: error)
    }
  }

  private func fetchImageUrls(_ localData: CurrentRotationLocalData)
    async throws(CurrentRotationError) -> [String: String]
  {
    do {
      let championIds = localData.rotation.allChampions
      let imageUrls = try await imageUrlProvider.champions(with: championIds)
      return Dictionary(uniqueKeysWithValues: zip(championIds, imageUrls))
    } catch {
      throw .championImagesUnavailable(cause: error)
    }
  }
}

extension DefaultRotationService {
  private func createRotation(
    _ patchVersion: String?,
    _ localData: CurrentRotationLocalData,
    _ imageUrlsByChampionId: [String: String]
  ) throws(CurrentRotationError) -> ChampionRotation {
    let (rotation, champions) = localData
    let championsByRiotId = champions.associateBy(\.riotId)

    func createChampion(riotId: String) throws(CurrentRotationError) -> Champion {
      guard let imageUrl = imageUrlsByChampionId[riotId] else {
        throw .championImageMissing(championId: riotId)
      }
      let champion = championsByRiotId[riotId]
      guard let id = champion?.id?.uuidString, let name = champion?.name else {
        throw .championDataMissing(championId: riotId)
      }
      return Champion(
        id: id,
        name: name,
        imageUrl: imageUrl
      )
    }

    let beginnerMaxLevel = rotation.beginnerMaxLevel
    let beginnerChampions = try rotation.beginnerChampions
      .map(createChampion).sorted { $0.name < $1.name }
    let regularChampions = try rotation.regularChampions
      .map(createChampion).sorted { $0.name < $1.name }

    guard let startDate = rotation.observedAt,
      let endDate = startDate.adding(2, .weekOfYear)
    else {
      throw .rotationDurationInvalid
    }
    let duration = ChampionRotationDuration(start: startDate, end: endDate)

    return ChampionRotation(
      patchVersion: patchVersion,
      duration: duration,
      beginnerMaxLevel: beginnerMaxLevel,
      beginnerChampions: beginnerChampions,
      regularChampions: regularChampions
    )
  }

  private func createRotationModel(_ riotData: CurrentRotationRiotData)
    throws(CurrentRotationError) -> ChampionRotationModel
  {
    let (championRotations, champions) = riotData
    let championsByRiotKey = champions.data.values.associateBy(\.key)

    func championRiotId(riotKey: Int) throws(CurrentRotationError) -> String {
      guard let data = championsByRiotKey[String(riotKey)] else {
        throw .unknownChampion(championKey: String(riotKey))
      }
      return data.id
    }

    let beginnerMaxLevel = championRotations.maxNewPlayerLevel
    let beginnerChampions = try championRotations.freeChampionIdsForNewPlayers
      .map(championRiotId).sorted()
    let regularChampions = try championRotations.freeChampionIds
      .map(championRiotId).sorted()

    return ChampionRotationModel(
      beginnerMaxLevel: beginnerMaxLevel,
      beginnerChampions: beginnerChampions,
      regularChampions: regularChampions
    )
  }
}

extension DefaultRotationService {
  private func loadRotationLocalData() async throws(CurrentRotationError)
    -> CurrentRotationLocalData
  {
    let rotation: ChampionRotationModel?
    let champions: [ChampionModel]
    do {
      rotation = try await appDatabase.mostRecentChampionRotation()
      champions = try await appDatabase.champions()
    } catch {
      throw .dataOperationFailed(cause: error)
    }
    guard let rotation else {
      throw .rotationDataMissing
    }
    return (rotation, champions)
  }

  private func saveChampionsData(_ riotData: CurrentRotationRiotData)
    async throws(CurrentRotationError)
  {
    do {
      let data = riotData.champions.data.values.toModels()
      try await appDatabase.saveChampionsFillingIds(data: data)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  private func saveRotationIfChanged(_ rotation: ChampionRotationModel)
    async throws(CurrentRotationError) -> Bool
  {
    do {
      let mostRecentRotation = try await appDatabase.mostRecentChampionRotation()
      if let mostRecentRotation, rotation.same(as: mostRecentRotation) {
        return false
      }

      try await appDatabase.addChampionRotation(data: rotation)

      return true
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }
}

extension ChampionRotationModel {
  var allChampions: [String] {
    (beginnerChampions + regularChampions).uniqued()
  }

  func same(as other: ChampionRotationModel) -> Bool {
    beginnerMaxLevel == other.beginnerMaxLevel
      && beginnerChampions.sorted() == other.beginnerChampions.sorted()
      && regularChampions.sorted() == other.regularChampions.sorted()
  }
}

private typealias CurrentRotationLocalData = (
  rotation: ChampionRotationModel,
  champions: [ChampionModel]
)

private typealias CurrentRotationRiotData = (
  championRotations: ChampionRotationsData,
  champions: ChampionsData
)

enum CurrentRotationError: Error {
  case riotDataUnavailable(cause: Error)
  case championImagesUnavailable(cause: Error)
  case unknownChampion(championKey: String)
  case championImageMissing(championId: String)
  case championDataMissing(championId: String)
  case rotationDataMissing
  case rotationDurationInvalid
  case dataOperationFailed(cause: Error)
}
