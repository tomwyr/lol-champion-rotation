struct ChampionsService {
  let imageUrlProvider: ImageUrlProvider
  let appDatabase: AppDatabase

  func getImageUrls(_ champions: [ChampionModel])
    async throws(ChampionsError) -> ChampionImageUrls
  {
    do {
      let championIds = champions.map(\.riotId)
      let imageUrls = try await imageUrlProvider.champions(with: championIds)
      let urlsById = Dictionary(uniqueKeysWithValues: zip(championIds, imageUrls))
      return ChampionImageUrls(imageUrlsByChampionId: urlsById)
    } catch {
      throw .championImagesUnavailable(cause: error)
    }
  }
}

enum ChampionsError: Error {
  case championDataInvalidOrMissing(championId: String?)
  case championImagesUnavailable(cause: Error)
  case dataOperationFailed(cause: Error)
  case championError(cause: ChampionError)
}
