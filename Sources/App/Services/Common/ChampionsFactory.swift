protocol ChampionRotationFactory {}

protocol ChampionFactory {
  var imageUrlProvider: ImageUrlProvider { get }

  func createChampion(model: ChampionModel) throws -> Champion
  func createChampions(for riotIds: [String], models: [ChampionModel]) throws -> [Champion]
  func createChampionDetails(
    model: ChampionModel,
    userWatchlists: UserWatchlistsModel?,
    availability: [ChampionDetailsAvailability],
    overview: ChampionDetailsOverview,
    history: [ChampionDetailsHistoryEvent]
  ) throws -> ChampionDetails
}

extension ChampionFactory {
  func createChampion(model: ChampionModel) throws -> Champion {
    let id = model.riotId.lowercased()
    let name = model.name
    let imageUrl = imageUrlProvider.champion(with: model.riotId)

    return Champion(
      id: id,
      name: name,
      imageUrl: imageUrl
    )
  }

  func createChampions(for riotIds: [String], models: [ChampionModel]) throws -> [Champion] {
    let modelsById = models.associatedBy(key: \.riotId)
    return try riotIds.map { id in
      guard let model = modelsById[id] else {
        throw ChampionError.dataMissing(championId: id)
      }
      return try createChampion(model: model)
    }
  }

  func createChampionDetails(
    model: ChampionModel,
    userWatchlists: UserWatchlistsModel?,
    availability: [ChampionDetailsAvailability],
    overview: ChampionDetailsOverview,
    history: [ChampionDetailsHistoryEvent]
  ) throws -> ChampionDetails {
    guard let championId = model.idString else {
      throw ChampionError.dataMissing(championId: model.riotId)
    }
    let id = model.riotId.lowercased()
    let name = model.name
    let title = model.title
    let imageUrl = imageUrlProvider.champion(with: model.riotId)
    let observing = userWatchlists?.champions.contains(championId)

    return ChampionDetails(
      id: id,
      name: name,
      title: title,
      imageUrl: imageUrl,
      observing: observing,
      availability: availability,
      overview: overview,
      history: history
    )
  }
}

enum ChampionError: Error {
  case dataMissing(championId: String)
}

extension ChampionsService: ChampionFactory {}

extension DefaultRotationService: ChampionFactory {}
