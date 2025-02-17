struct ChampionImageUrls {
  let imageUrlsByChampionId: [String: String]

  func get(for championRiotId: String) throws(ChampionRotationError) -> String {
    guard let imageUrl = imageUrlsByChampionId[championRiotId] else {
      throw .championImageMissing(championId: championRiotId)
    }
    return imageUrl
  }
}

struct ChampionFactory {
  init(champions: [ChampionModel], imageUrls: ChampionImageUrls) {
    self.championsByRiotId = champions.associateBy(\.riotId)
    self.imageUrls = imageUrls
  }

  let championsByRiotId: [String: ChampionModel]
  let imageUrls: ChampionImageUrls

  func create(riotId: String) throws(ChampionRotationError) -> Champion {
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
}
