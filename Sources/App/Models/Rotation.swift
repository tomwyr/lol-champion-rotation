import Vapor

struct ChampionRotation: Content {
    let beginnerMaxLevel: Int
    let beginnerChampions: [Champion]
    let regularChampions: [Champion]

    func toSnapshot() -> ChampionRotationSnapshot {
        .init(
            beginnerMaxLevel: beginnerMaxLevel,
            beginnerChampionIds: beginnerChampions.map(\.id),
            regularChampionIds: regularChampions.map(\.id)
        )
    }
}

struct ChampionRotationSnapshot: Content {
    let beginnerMaxLevel: Int
    let beginnerChampionIds: [String]
    let regularChampionIds: [String]

    func same(as other: ChampionRotationSnapshot) -> Bool {
        beginnerMaxLevel == other.beginnerMaxLevel
            && beginnerChampionIds.sorted() == other.beginnerChampionIds.sorted()
            && regularChampionIds.sorted() == other.regularChampionIds.sorted()
    }
}

struct Champion: Content {
    let id: String
    let name: String
    let imageUrl: String
}

struct RefreshRotationResult: Content {
    let rotationChanged: Bool
}
