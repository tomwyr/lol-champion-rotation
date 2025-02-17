import Foundation

extension DefaultRotationService {
  func currentRotation() async throws(ChampionRotationError) -> ChampionRotation {
    let patchVersion = try? await versionService.latestVersion()
    let localData = try await loadCurrentRotationLocalData()
    let imageUrls = try await fetchImageUrls(localData)
    return try await createChampionRotation(patchVersion, localData, imageUrls)
  }

  private func loadCurrentRotationLocalData() async throws(ChampionRotationError)
    -> CurrentRotationLocalData
  {
    let regularRotation: RegularChampionRotationModel?
    let beginnerRotation: BeginnerChampionRotationModel?
    let champions: [ChampionModel]
    let hasPreviousRegularRotation: Bool
    do {
      regularRotation = try await appDatabase.mostRecentRegularRotation()
      beginnerRotation = try await appDatabase.mostRecentBeginnerRotation()
      champions = try await appDatabase.champions()
      if let rotationId = regularRotation?.id?.uuidString {
        let previousRotation = try await appDatabase.findPreviousRegularRotation(before: rotationId)
        hasPreviousRegularRotation = previousRotation != nil
      } else {
        hasPreviousRegularRotation = false
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
      hasPreviousRegularRotation
    )
  }

  private func fetchImageUrls(_ localData: CurrentRotationLocalData)
    async throws(ChampionRotationError) -> ChampionImageUrls
  {
    let (regularRotation, beginnerRotation, _, _) = localData
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
  ) async throws(ChampionRotationError) -> ChampionRotation {
    let championFactory = ChampionFactory(champions: data.champions, imageUrls: imageUrls)

    let beginnerMaxLevel = data.beginnerRotation.maxLevel
    let beginnerChampions = try data.beginnerRotation.champions
      .map(championFactory.create).sorted { $0.name < $1.name }
    let regularChampions = try data.regularRotation.champions
      .map(championFactory.create).sorted { $0.name < $1.name }

    let duration = try await getRotationDuration(data.regularRotation)

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

private typealias CurrentRotationLocalData = (
  regularRotation: RegularChampionRotationModel,
  beginnerRotation: BeginnerChampionRotationModel,
  champions: [ChampionModel],
  hasPreviousRegularRotation: Bool
)
