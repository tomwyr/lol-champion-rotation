struct ChampionsService {
  let imageUrlProvider: ImageUrlProvider
  let appDb: AppDatabase
  let seededSelector: SeededSelector

  typealias OutError = ChampionsError
}

enum ChampionsError: Error {
  case dataInvalidOrMissing(championId: String?)
  case dataInvalidOrMissing(riotId: String)
  case dataOperationFailed(cause: Error)
  case rotationDurationError(cause: RotationDurationError)
  case observedChampionDataInvalid(userId: String)
  case championError(cause: ChampionError)
}
