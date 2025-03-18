struct ChampionsService {
  let imageUrlProvider: ImageUrlProvider
  let appDatabase: AppDatabase
  let seededSelector: SeededSelector

  typealias OutError = ChampionsError
}

enum ChampionsError: Error {
  case dataInvalidOrMissing(championId: String?)
  case dataOperationFailed(cause: Error)
  case rotationDurationError(cause: RotationDurationError)
  case observedChampionDataInvalid(userId: String)
  case championError(cause: ChampionError)
}
