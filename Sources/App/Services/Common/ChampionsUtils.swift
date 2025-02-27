struct ChampionFactory<OutError: Error> {
  init(
    champions: [ChampionModel],
    imageUrls: ChampionImageUrls,
    wrapError: @escaping (ChampionError) -> OutError
  ) {
    self.championsByRiotId = champions.associateBy(\.riotId)
    self.imageUrls = imageUrls
    self.wrapError = wrapError
  }

  let championsByRiotId: [String: ChampionModel]
  let imageUrls: ChampionImageUrls
  let wrapError: (ChampionError) -> OutError

  func create(riotId: String) throws(OutError) -> Champion {
    let imageUrl: String
    do {
      imageUrl = try imageUrls.get(for: riotId)
    } catch {
      throw wrapError(.dataMissing(championId: riotId))
    }

    let champion = championsByRiotId[riotId]
    guard let id = champion?.id?.uuidString, let name = champion?.name else {
      throw wrapError(.dataMissing(championId: riotId))
    }

    return Champion(
      id: id,
      name: name,
      imageUrl: imageUrl
    )
  }

  func createDetails(
    riotId: String,
    availability: [ChampionDetailsAvailability]
  ) throws(OutError) -> ChampionDetails {
    let imageUrl: String
    do {
      imageUrl = try imageUrls.get(for: riotId)
    } catch {
      throw wrapError(.dataMissing(championId: riotId))
    }

    let champion = championsByRiotId[riotId]
    guard let id = champion?.id?.uuidString,
      let name = champion?.name, let title = champion?.title
    else {
      throw wrapError(.dataMissing(championId: riotId))
    }

    return ChampionDetails(
      id: id,
      name: name,
      title: title,
      imageUrl: imageUrl,
      availability: availability
    )
  }
}

struct ChampionImageUrls {
  let imageUrlsByChampionId: [String: String]

  func get(for championRiotId: String) throws(ChampionError) -> String {
    guard let imageUrl = imageUrlsByChampionId[championRiotId] else {
      throw .imageMissing(championId: championRiotId)
    }
    return imageUrl
  }
}

enum ChampionError: Error {
  case imageMissing(championId: String)
  case dataMissing(championId: String)
}
