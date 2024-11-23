import Vapor

struct ChampionRotation: Content {
  let beginnerMaxLevel: Int
  let beginnerChampions: [Champion]
  let regularChampions: [Champion]
}

struct Champion: Content {
  let id: String
  let name: String
  let imageUrl: String
}

struct RefreshRotationResult: Content {
  let rotationChanged: Bool
}
