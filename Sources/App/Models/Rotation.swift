import Vapor

struct CurrentChampionRotation: Content {
  let id: String
  let patchVersion: String?
  let duration: ChampionRotationDuration
  let beginnerMaxLevel: Int
  let beginnerChampions: [Champion]
  let regularChampions: [Champion]
  let nextRotationToken: String?
}

struct ChampionRotationSummary: Content {
  let id: String
  let duration: ChampionRotationDuration
  let champions: [Champion]
}

struct ChampionRotationDetails: Content {
  let id: String
  let duration: ChampionRotationDuration
  let champions: [Champion]
  let current: Bool
  let observing: Bool?
}

struct RegularChampionRotation: Content {
  let id: String
  let patchVersion: String?
  let duration: ChampionRotationDuration
  let champions: [Champion]
  let nextRotationToken: String?
  let current: Bool
}

struct ChampionRotationPrediction: Content {
  let duration: ChampionRotationDuration
  let champions: [Champion]
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
  let championsAdded: Bool
}

struct FilterRotationsResult: Content {
  let regularRotations: [FilteredRegularRotation]
  let beginnerRotation: FilteredBeginnerRotation?
}

struct FilteredRegularRotation: Content {
  let champions: [Champion]
  let duration: ChampionRotationDuration
  let current: Bool
}

struct FilteredBeginnerRotation: Content {
  let champions: [Champion]
}

struct ObservedRotationsData: Content {
  let rotations: [ObservedRotation]
}

struct ObservedRotation: Content {
  let id: String
  let duration: ChampionRotationDuration
  let current: Bool
  let championImageUrls: [String]
}

struct UpdateObserveRotationInput: Content {
  let observing: Bool
}

enum ChampionRotationType: String, Content {
  case regular = "regular"
  case beginner = "beginner"
}
