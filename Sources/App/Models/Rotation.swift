import Vapor

struct ChampionRotation: Content {
    let champions: [Champion]
}

struct Champion: Content {
    let name: String
}
