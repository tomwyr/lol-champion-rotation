struct ChampionsService {
  let imageUrlProvider: ImageUrlProvider
  let appDb: AppDatabase
  let seededSelector: SeededSelector
}

enum ChampionsError: Error {
  case dataInvalidOrMissing(championId: String?)
  case dataInvalidOrMissing(riotId: String)
}
