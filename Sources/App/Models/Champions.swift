import Vapor

struct ChampionDetails: Content {
  let id: String
  let name: String
  let title: String
  let imageUrl: String
  let availability: [ChampionDetailsAvailability]
  // let overview: ChampionDetailsOverview
  // let rotation: [ChampionDetailsRotation]
}

struct ChampionDetailsAvailability: Content {
  let rotationType: ChampionRotationType
  let lastAvailable: Date?
  let current: Bool
}

struct ChampionDetailsOverview: Content {
  let occurences: Int
  let popularity: Int
  let lastAvailable: Date?
  let rotationsSinceLastAvailable: Int?
}

struct ChampionDetailsRotation: Content {
  let id: String
  let duration: ChampionRotationDuration
  let current: Bool
  let rotationsSinceLastSeen: Int
  let championImageUrls: [String]
}

struct SearchChampionsResult: Content {
  let matches: [SearchChampionsMatch]
}

struct SearchChampionsMatch: Content {
  let champion: Champion
  let availableIn: [ChampionRotationType]
}
