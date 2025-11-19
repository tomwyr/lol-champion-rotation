import Foundation

extension DefaultRotationService {
  func refreshRotation() async throws(ChampionRotationError) -> RefreshRotationResult {
    let localData = try await loadLocalData()
    let riotData = try await fetchRotationRiotData()
    let rotations = try createRotationModels(localData, riotData)
    let rotationChanged = try await saveRotationsIfChanged(rotations)
    let championsAdded = try await saveChampionsData(riotData)
    if rotationChanged {
      _ = try await predictRotation()
    }
    return RefreshRotationResult(
      rotationChanged: rotationChanged,
      championsAdded: championsAdded,
    )
  }

  private func loadLocalData() async throws(ChampionRotationError) -> RefreshRotationLocalData {
    do {
      let patchVersions = try await appDb.patchVersions()
      let existingSlugs = try await appDb.regularRotationSlugs()
      return (patchVersions: patchVersions, existingSlugs: existingSlugs)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
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

  private func createRotationModels(
    _ localData: RefreshRotationLocalData,
    _ riotData: CurrentRotationRiotData,
  ) throws(ChampionRotationError) -> ChampionRotationModels {
    let (patchVersions, existingSlugs) = localData

    let (championRotations, champions) = riotData
    let championsByRiotKey = champions.data.values.associatedBy(key: \.key)

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

    let observedAt = instant.now
    let slug: String
    do {
      slug = try slugGenerator.resolveUnique(
        rotationStart: observedAt,
        versions: patchVersions,
        existingSlugs: existingSlugs,
      )
    } catch {
      throw .slugError(cause: error)
    }

    let regularRotation = RegularChampionRotationModel(
      observedAt: observedAt,
      champions: regularChampions,
      slug: slug
    )
    let beginnerRotation = BeginnerChampionRotationModel(
      observedAt: instant.now,
      maxLevel: beginnerMaxLevel,
      champions: beginnerChampions
    )

    return (regularRotation, beginnerRotation)
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

  private func saveChampionsData(_ riotData: CurrentRotationRiotData)
    async throws(ChampionRotationError) -> [String]
  {
    do {
      let data = riotData.champions.data.values.toModels()
      let createdChampionsIds = try await appDb.saveChampions(data: data)
      return createdChampionsIds
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  private func saveRegularRotation(_ rotation: RegularChampionRotationModel) async throws -> Bool {
    let mostRecentRotation = try await appDb.currentRegularRotation()
    if let mostRecentRotation, rotation.same(as: mostRecentRotation) {
      return false
    }
    try await appDb.addRegularRotation(data: rotation)
    return true
  }

  private func saveBeginnerRotation(_ rotation: BeginnerChampionRotationModel) async throws -> Bool
  {
    let mostRecentRotation = try await appDb.currentBeginnerRotation()
    if let mostRecentRotation, rotation.same(as: mostRecentRotation) {
      return false
    }
    try await appDb.addBeginnerRotation(data: rotation)
    return true
  }
}

private typealias RefreshRotationLocalData = (
  patchVersions: [PatchVersionModel],
  existingSlugs: [String],
)

private typealias CurrentRotationRiotData = (
  championRotations: ChampionRotationsData,
  champions: ChampionsData
)

private typealias ChampionRotationModels = (
  regular: RegularChampionRotationModel,
  beginner: BeginnerChampionRotationModel
)
