import Vapor

struct ChampionRotation: Content {
  let patchVersion: String?
  let duration: ChampionRotationDuration
  let beginnerMaxLevel: Int
  let beginnerChampions: [Champion]
  let regularChampions: [Champion]
  let nextRotationToken: String?
}

struct RegularChampionRotation: Content {
  let patchVersion: String?
  let duration: ChampionRotationDuration
  let champions: [Champion]
  let nextRotationToken: String?
}

struct ChampionRotationDuration: Content {
  let start: Date
  let end: Date
}

struct Champion: Content {
  let id: String
  let name: String
  let imageUrl: String
}

struct RefreshRotationResult: Content {
  let rotationChanged: Bool
}

struct FilterRotationsResult: Content {
  let query: String
  let rotations: [FilteredRotation]
}

struct FilteredRotation: Content {
  let duration: ChampionRotationDuration
  let champions: [Champion]
}
