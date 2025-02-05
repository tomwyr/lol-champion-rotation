import Foundation

protocol RotationService {
  func currentRotation() async throws(ChampionRotationError) -> ChampionRotation
  func rotation(nextRotationToken: String) async throws(ChampionRotationError)
    -> RegularChampionRotation?
  func refreshRotation() async throws(ChampionRotationError) -> RefreshRotationResult
}

struct DefaultRotationService: RotationService {
  let imageUrlProvider: ImageUrlProvider
  let riotApiClient: RiotApiClient
  let appDatabase: AppDatabase
  let versionService: VersionService
  let notificationsService: NotificationsService
  let idHasher: IdHasher
}
extension DefaultRotationService {
  func currentRotation() async throws(ChampionRotationError) -> ChampionRotation {
    let patchVersion = try? await versionService.latestVersion()
    let localData = try await loadCurrentRotationLocalData()
    let imageUrls = try await fetchImageUrls(localData)
    return try createChampionRotation(patchVersion, localData, imageUrls)
  }

  private func loadCurrentRotationLocalData() async throws(ChampionRotationError)
    -> CurrentRotationLocalData
  {
    let regularRotation: RegularChampionRotationModel?
    let beginnerRotation: BeginnerChampionRotationModel?
    let champions: [ChampionModel]
    let hasPreviousRegularRotation: Bool
    let nextRegularRotationDate: Date?
    do {
      regularRotation = try await appDatabase.mostRecentRegularRotation()
      beginnerRotation = try await appDatabase.mostRecentBeginnerRotation()
      champions = try await appDatabase.champions()
      if let rotationId = regularRotation?.id?.uuidString {
        let previousRotation = try await appDatabase.findPreviousRegularRotation(before: rotationId)
        let nextRotation = try await appDatabase.findNextRegularRotation(after: rotationId)
        hasPreviousRegularRotation = previousRotation != nil
        nextRegularRotationDate = nextRotation?.observedAt
      } else {
        hasPreviousRegularRotation = false
        nextRegularRotationDate = nil
      }
    } catch {
      throw .dataOperationFailed(cause: error)
    }
    guard let regularRotation, let beginnerRotation else {
      throw .currentRotationDataMissing
    }
    return (
      regularRotation,
      beginnerRotation,
      champions,
      hasPreviousRegularRotation,
      nextRegularRotationDate
    )
  }

  private func fetchImageUrls(_ localData: CurrentRotationLocalData)
    async throws(ChampionRotationError) -> ChampionImageUrls
  {
    let (regularRotation, beginnerRotation, _, _, _) = localData
    do {
      let championIds = (regularRotation.champions + beginnerRotation.champions).uniqued()
      let imageUrls = try await imageUrlProvider.champions(with: championIds)
      let urlsById = Dictionary(uniqueKeysWithValues: zip(championIds, imageUrls))
      return ChampionImageUrls(imageUrlsByChampionId: urlsById)
    } catch {
      throw .championImagesUnavailable(cause: error)
    }
  }

  private func createChampionRotation(
    _ patchVersion: String?,
    _ data: CurrentRotationLocalData,
    _ imageUrls: ChampionImageUrls
  ) throws(ChampionRotationError) -> ChampionRotation {
    let championsByRiotId = data.champions.associateBy(\.riotId)

    func createChampion(riotId: String) throws(ChampionRotationError) -> Champion {
      let imageUrl = try imageUrls.get(for: riotId)
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

    let beginnerMaxLevel = data.beginnerRotation.maxLevel
    let beginnerChampions = try data.beginnerRotation.champions
      .map(createChampion).sorted { $0.name < $1.name }
    let regularChampions = try data.regularRotation.champions
      .map(createChampion).sorted { $0.name < $1.name }

    let duration = try getRotationDuration(data.regularRotation, data.nextRegularRotationDate)

    let nextRotationToken =
      // Rotation is `previous` chronologically but `next` from the loading more data point of view.
      if data.hasPreviousRegularRotation {
        try getNextRotationToken(data.regularRotation)
      } else {
        nil as String?
      }

    return ChampionRotation(
      patchVersion: patchVersion,
      duration: duration,
      beginnerMaxLevel: beginnerMaxLevel,
      beginnerChampions: beginnerChampions,
      regularChampions: regularChampions,
      nextRotationToken: nextRotationToken
    )
  }
}

extension DefaultRotationService {
  func rotation(nextRotationToken: String) async throws(ChampionRotationError)
    -> RegularChampionRotation?
  {
    let localData = try await loadRegularRotationLocalData(nextRotationToken: nextRotationToken)
    guard let localData else { return nil }
    let nextRotationTime = localData.rotation.observedAt
    let patchVersion = try? await versionService.findVersion(olderThan: nextRotationTime)
    let imageUrlsByChampionId = try await fetchImageUrls(localData)
    return try createRegularRotation(patchVersion, localData, imageUrlsByChampionId)
  }

  private func loadRegularRotationLocalData(nextRotationToken: String)
    async throws(ChampionRotationError) -> RegularRotationLocalData?
  {
    let nextRotationId: String
    do {
      nextRotationId = try idHasher.tokenToId(nextRotationToken)
    } catch {
      throw .tokenHashingFailed(cause: error)
    }

    let rotation: RegularChampionRotationModel?
    let champions: [ChampionModel]
    let hasPreviousRegularRotation: Bool
    let nextRegularRotationDate: Date?
    do {
      rotation = try await appDatabase.findPreviousRegularRotation(before: nextRotationId)
      champions = try await appDatabase.champions()
      if let rotationId = rotation?.id?.uuidString {
        let previousRotation = try await appDatabase.findPreviousRegularRotation(before: rotationId)
        let nextRotation = try await appDatabase.findNextRegularRotation(after: rotationId)
        hasPreviousRegularRotation = previousRotation != nil
        nextRegularRotationDate = nextRotation?.observedAt
      } else {
        hasPreviousRegularRotation = false
        nextRegularRotationDate = nil
      }
    } catch {
      throw .dataOperationFailed(cause: error)
    }
    guard let rotation else {
      return nil
    }
    return (rotation, champions, hasPreviousRegularRotation, nextRegularRotationDate)
  }

  private func fetchImageUrls(_ localData: RegularRotationLocalData)
    async throws(ChampionRotationError) -> ChampionImageUrls
  {
    do {
      let championIds = localData.rotation.champions
      let imageUrls = try await imageUrlProvider.champions(with: championIds)
      let urlsById = Dictionary(uniqueKeysWithValues: zip(championIds, imageUrls))
      return ChampionImageUrls(imageUrlsByChampionId: urlsById)
    } catch {
      throw .championImagesUnavailable(cause: error)
    }
  }

  private func createRegularRotation(
    _ patchVersion: String?,
    _ data: RegularRotationLocalData,
    _ imageUrls: ChampionImageUrls
  ) throws(ChampionRotationError) -> RegularChampionRotation {
    let championsByRiotId = data.champions.associateBy(\.riotId)

    func createChampion(riotId: String) throws(ChampionRotationError) -> Champion {
      let imageUrl = try imageUrls.get(for: riotId)
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

    let champions = try data.rotation.champions
      .map(createChampion).sorted { $0.name < $1.name }

    let duration = try getRotationDuration(data.rotation, data.nextRegularRotationDate)

    let nextRotationToken =
      // Rotation is `previous` chronologically but `next` from the loading more data point of view.
      if data.hasPreviousRegularRotation {
        try getNextRotationToken(data.rotation)
      } else {
        nil as String?
      }

    return RegularChampionRotation(
      patchVersion: patchVersion,
      duration: duration,
      champions: champions,
      nextRotationToken: nextRotationToken
    )
  }
}

extension DefaultRotationService {
  func refreshRotation() async throws(ChampionRotationError) -> RefreshRotationResult {
    let riotData = try await fetchRotationRiotData()
    let rotations = try createRotationModels(riotData)
    let rotationChanged = try await saveRotationsIfChanged(rotations)
    try await saveChampionsData(riotData)
    if rotationChanged {
      try? await notificationsService.notifyRotationChanged()
    }
    return RefreshRotationResult(rotationChanged: rotationChanged)
  }

  private func fetchRotationRiotData() async throws(ChampionRotationError)
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

  private func createRotationModels(_ riotData: CurrentRotationRiotData)
    throws(ChampionRotationError) -> ChampionRotationModels
  {
    let (championRotations, champions) = riotData
    let championsByRiotKey = champions.data.values.associateBy(\.key)

    func championRiotId(riotKey: Int) throws(ChampionRotationError) -> String {
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

    let regularRotation = RegularChampionRotationModel(
      observedAt: Date.now,
      champions: regularChampions
    )
    let beginnerRotation = BeginnerChampionRotationModel(
      observedAt: Date.now,
      maxLevel: beginnerMaxLevel,
      champions: beginnerChampions
    )

    return (regularRotation, beginnerRotation)
  }
}

extension DefaultRotationService {
}

extension DefaultRotationService {

  private func getRotationDuration(
    _ rotation: RegularChampionRotationModel,
    _ nextRotationDate: Date?
  ) throws(ChampionRotationError) -> ChampionRotationDuration {
    let startDate = rotation.observedAt
    guard let endDate = nextRotationDate ?? startDate.adding(1, .weekOfYear) else {
      throw .rotationDurationInvalid
    }
    return ChampionRotationDuration(start: startDate, end: endDate)
  }

  private func getNextRotationToken(_ rotation: RegularChampionRotationModel)
    throws(ChampionRotationError) -> String?
  {
    let rotationId = rotation.id!.uuidString
    do {
      return try idHasher.idToToken(rotationId)
    } catch {
      throw .tokenHashingFailed(cause: error)
    }
  }

  private func saveRotationsIfChanged(_ rotations: ChampionRotationModels)
    async throws(ChampionRotationError) -> Bool
  {
    do {
      let regularRotationChanged = try await saveRegularRotation(rotations.regular)
      let beginnerRotationChanged = try await saveBeginnerRotation(rotations.beginner)
      return regularRotationChanged || beginnerRotationChanged
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  private func saveRegularRotation(_ rotation: RegularChampionRotationModel) async throws -> Bool {
    let mostRecentRotation = try await appDatabase.mostRecentRegularRotation()
    if let mostRecentRotation, rotation.same(as: mostRecentRotation) {
      return false
    }
    try await appDatabase.addRegularRotation(data: rotation)
    return true
  }

  private func saveBeginnerRotation(_ rotation: BeginnerChampionRotationModel) async throws -> Bool
  {
    let mostRecentRotation = try await appDatabase.mostRecentBeginnerRotation()
    if let mostRecentRotation, rotation.same(as: mostRecentRotation) {
      return false
    }
    try await appDatabase.addBeginnerRotation(data: rotation)
    return true
  }

  private func saveChampionsData(_ riotData: CurrentRotationRiotData)
    async throws(ChampionRotationError)
  {
    do {
      let data = riotData.champions.data.values.toModels()
      try await appDatabase.saveChampionsFillingIds(data: data)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }
}

private typealias ChampionRotationModels = (
  regular: RegularChampionRotationModel,
  beginner: BeginnerChampionRotationModel
)

private typealias CurrentRotationLocalData = (
  regularRotation: RegularChampionRotationModel,
  beginnerRotation: BeginnerChampionRotationModel,
  champions: [ChampionModel],
  hasPreviousRegularRotation: Bool,
  nextRegularRotationDate: Date?
)

private typealias RegularRotationLocalData = (
  rotation: RegularChampionRotationModel,
  champions: [ChampionModel],
  hasPreviousRegularRotation: Bool,
  nextRegularRotationDate: Date?
)

private typealias CurrentRotationRiotData = (
  championRotations: ChampionRotationsData,
  champions: ChampionsData
)

enum ChampionRotationError: Error {
  case riotDataUnavailable(cause: Error)
  case championImagesUnavailable(cause: Error)
  case unknownChampion(championKey: String)
  case championImageMissing(championId: String)
  case championDataMissing(championId: String)
  case currentRotationDataMissing
  case rotationDurationInvalid
  case tokenHashingFailed(cause: Error)
  case dataOperationFailed(cause: Error)
}

struct ChampionImageUrls {
  let imageUrlsByChampionId: [String: String]

  func get(for championRiotId: String) throws(ChampionRotationError) -> String {
    guard let imageUrl = imageUrlsByChampionId[championRiotId] else {
      throw .championImageMissing(championId: championRiotId)
    }
    return imageUrl
  }
}
