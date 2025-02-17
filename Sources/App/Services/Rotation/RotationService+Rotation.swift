import Foundation

extension DefaultRotationService {
  func rotation(nextRotationToken: String) async throws(ChampionRotationError)
    -> RegularChampionRotation?
  {
    let localData = try await loadRegularRotationLocalData(nextRotationToken: nextRotationToken)
    guard let localData else { return nil }
    let nextRotationTime = localData.rotation.observedAt
    let patchVersion = try? await versionService.findVersion(olderThan: nextRotationTime)
    let imageUrlsByChampionId = try await fetchImageUrls(localData)
    return try await createRegularRotation(patchVersion, localData, imageUrlsByChampionId)
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
    do {
      rotation = try await appDatabase.findPreviousRegularRotation(before: nextRotationId)
      champions = try await appDatabase.champions()
      if let rotationId = rotation?.id?.uuidString {
        let previousRotation = try await appDatabase.findPreviousRegularRotation(before: rotationId)
        hasPreviousRegularRotation = previousRotation != nil
      } else {
        hasPreviousRegularRotation = false
      }
    } catch {
      throw .dataOperationFailed(cause: error)
    }
    guard let rotation else {
      return nil
    }
    return (rotation, champions, hasPreviousRegularRotation)
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
  ) async throws(ChampionRotationError) -> RegularChampionRotation {
    let championFactory = ChampionFactory(champions: data.champions, imageUrls: imageUrls)
    let champions = try data.rotation.champions
      .map(championFactory.create)
      .sorted { $0.name < $1.name }

    let duration = try await getRotationDuration(data.rotation)

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

private typealias RegularRotationLocalData = (
  rotation: RegularChampionRotationModel,
  champions: [ChampionModel],
  hasPreviousRegularRotation: Bool
)
