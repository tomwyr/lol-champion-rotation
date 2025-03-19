protocol ChampionFactory {
  associatedtype OutError: Error

  var imageUrlProvider: ImageUrlProvider { get }

  func createChampion(model: ChampionModel) throws(OutError) -> Champion

  func createChampions(for riotIds: [String], models: [ChampionModel]) throws(OutError)
    -> [Champion]

  func createChampionDetails(
    model: ChampionModel,
    userWatchlists: UserWatchlistsModel?,
    availability: [ChampionDetailsAvailability],
    overview: ChampionDetailsOverview,
    history: [ChampionDetailsHistoryEvent]
  ) throws(OutError) -> ChampionDetails

  func wrapError(_ error: ChampionError) -> OutError
}

extension ChampionFactory {
  func createChampion(model: ChampionModel) throws(OutError) -> Champion {
    guard let id = model.idString else {
      throw wrapError(.dataMissing(championId: model.riotId))
    }
    let name = model.name
    let imageUrl = imageUrlProvider.champion(with: model.riotId)

    return Champion(
      id: id,
      name: name,
      imageUrl: imageUrl
    )
  }

  func createChampions(for riotIds: [String], models: [ChampionModel]) throws(OutError)
    -> [Champion]
  {
    let modelsById = models.associatedBy(\.riotId)
    return try riotIds.map { id throws(OutError) in
      guard let model = modelsById[id] else {
        throw wrapError(.dataMissing(championId: id))
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
  ) throws(OutError) -> ChampionDetails {
    guard let championId = model.idString else {
      throw wrapError(.dataMissing(championId: model.riotId))
    }
    let name = model.name
    let title = model.title
    let imageUrl = imageUrlProvider.champion(with: model.riotId)
    let observing = userWatchlists?.champions.contains(championId)

    return ChampionDetails(
      id: championId,
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

extension ChampionsService: ChampionFactory {
  func wrapError(_ error: ChampionError) -> ChampionsError {
    .championError(cause: error)
  }
}

extension DefaultRotationService: ChampionFactory {
  func wrapError(_ error: ChampionError) -> ChampionRotationError {
    .championError(cause: error)
  }
}
