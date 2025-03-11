import Vapor

struct ChampionDetails: Content {
  let id: String
  let name: String
  let title: String
  let imageUrl: String
  let availability: [ChampionDetailsAvailability]
  let overview: ChampionDetailsOverview
  let history: [ChampionDetailsHistoryEvent]
}

struct ChampionDetailsAvailability: Content {
  let rotationType: ChampionRotationType
  let lastAvailable: Date?
  let current: Bool
}

struct ChampionDetailsOverview: Content {
  let occurrences: Int
  let popularity: Int
  let currentStreak: Int?
}

enum ChampionDetailsHistoryEvent: Content {
  case rotation(ChampionDetailsHistoryRotation)
  case bench(ChampionDetailsHistoryBench)
  case release(ChampionDetailsHistoryRelease)
}

struct ChampionDetailsHistoryRotation: Content {
  let id: String
  let duration: ChampionRotationDuration
  let current: Bool
  let championImageUrls: [String]
}

struct ChampionDetailsHistoryBench: Content {
  let rotationsMissed: Int
}

struct ChampionDetailsHistoryRelease: Content {
  let releasedAt: Date
}

struct SearchChampionsResult: Content {
  let matches: [SearchChampionsMatch]
}

struct SearchChampionsMatch: Content {
  let champion: Champion
  let availableIn: [ChampionRotationType]
}
