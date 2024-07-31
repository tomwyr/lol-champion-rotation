import Vapor

struct ChampionRotation: Content {
    let playerLevelCap: Int
    let champions: [Champion]
}

struct Champion: Content {
    let id: String
    let name: String
    let levelCapped: Bool
    let imageUrl: String
}
