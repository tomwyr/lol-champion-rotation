import Foundation
import Vapor

extension DefaultRotationService {
  func refreshRotation() async throws -> RefreshRotationResult {
    log("Loading local data")
    let localData = try await loadLocalData()
    log("Fetching riot data")
    let riotData = try await fetchRotationRiotData()

    log("Creating rotations")
    let rotations = try createRotationModels(localData, riotData)
    log("Saving rotations")
    let rotationChanged = try await saveRotationsIfChanged(rotations)
    log("Saving champions")
    let championsAdded = try await saveChampionsData(riotData)

    if rotationChanged {
      log("Predicting rotation")
      _ = try await predictRotation()
    }

    log("Refreshing rotation done")
    return RefreshRotationResult(
      rotationChanged: rotationChanged,
      championsAdded: championsAdded,
    )
  }

  private func loadLocalData() async throws -> RefreshRotationLocalData {
    log("Loading patch versions")
    let patchVersions = try await appDb.patchVersions()
    log("Loading rotations slugs")
    let existingSlugs = try await appDb.regularRotationSlugs()
    return (patchVersions, existingSlugs)
  }

  private func fetchRotationRiotData() async throws -> CurrentRotationRiotData {
    log("Fetching rotations")
    let championRotations = try await riotApiClient.championRotations()
    log("Loading latest version")
    let version = try await versionService.latestVersion()
    log("Fetching champions")
    let champions = try await riotApiClient.champions(version: version)
    return (championRotations, champions)
  }

  private func createRotationModels(
    _ localData: RefreshRotationLocalData,
    _ riotData: CurrentRotationRiotData,
  ) throws -> ChampionRotationModels {
    let (patchVersions, existingSlugs) = localData
    let (championRotations, champions) = riotData

    let championsByRiotKey = champions.data.values.associatedBy(key: \.key)
    func championRiotId(riotKey: Int) throws -> String {
      guard let data = championsByRiotKey[String(riotKey)] else {
        throw ChampionRotationError.unknownChampion(championKey: String(riotKey))
      }
      return data.id
    }

    let beginnerMaxLevel = championRotations.maxNewPlayerLevel
    let beginnerChampions = try championRotations.freeChampionIdsForNewPlayers
      .map(championRiotId).sorted()
    let regularChampions = try championRotations.freeChampionIds
      .map(championRiotId).sorted()

    let observedAt = instant.now
    let slug = try slugGenerator.resolveUnique(
      rotationStart: observedAt,
      versions: patchVersions,
      existingSlugs: existingSlugs,
    )

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

  private func saveRotationsIfChanged(_ rotations: ChampionRotationModels) async throws -> Bool {
    log("Saving regular rotation")
    let regularRotationChanged = try await saveRegularRotation(rotations.regular)
    log("Saving beginner rotation")
    let beginnerRotationChanged = try await saveBeginnerRotation(rotations.beginner)
    return regularRotationChanged || beginnerRotationChanged

  }

  private func saveRegularRotation(_ rotation: RegularChampionRotationModel) async throws -> Bool {
    log("Load current regular rotation from database")
    let mostRecentRotation = try await appDb.currentRegularRotation()
    if let mostRecentRotation, rotation.same(as: mostRecentRotation) {
      return false
    }
    log("Add new regular rotation to database")
    try await appDb.addRegularRotation(data: rotation)
    return true
  }

  private func saveBeginnerRotation(
    _ rotation: BeginnerChampionRotationModel,
  ) async throws -> Bool {
    log("Load current beginner rotation from database")
    let mostRecentRotation = try await appDb.currentBeginnerRotation()
    if let mostRecentRotation, rotation.same(as: mostRecentRotation) {
      return false
    }
    log("Add new beginner rotation to database")
    try await appDb.addBeginnerRotation(data: rotation)
    return true
  }

  private func saveChampionsData(_ riotData: CurrentRotationRiotData) async throws -> [String] {
    let data = riotData.champions.data.values.toModels()
    log("Add champions to database")
    let createdChampionsIds = try await appDb.saveChampions(data: data)
    return createdChampionsIds.sorted()
  }

  private func log(_ message: String) {
    logger.info("[refresh-rotation] \(message)")
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
