struct ChampionRotation: Codable {
    let beginnerMaxLevel: Int
    let beginnerChampions: [Champion]
    let regularChampions: [Champion]
}

struct Champion: Codable {
    let id: String
    let name: String
    let imageUrl: String
}

enum CurrentRotationError: Error {
    case unavailable
}
