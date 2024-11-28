import Vapor

struct ChampionRotation: Content {
  let duration: ChampionRotationDuration?
  let beginnerMaxLevel: Int
  let beginnerChampions: [Champion]
  let regularChampions: [Champion]
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
