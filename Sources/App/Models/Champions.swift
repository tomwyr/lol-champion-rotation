import Vapor

struct SearchChampionsResult: Content {
  let matches: [SearchChampionsMatch]
}

struct SearchChampionsMatch: Content {
  let champion: Champion
  let availableIn: [ChampionRotationType]
}
