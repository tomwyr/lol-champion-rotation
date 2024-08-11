import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

struct RiotApiClient {
    let http: HttpClient
    let apiKey: String

    func championRotations() async throws -> ChampionRotationsData {
        try await getWithAuth(from: championRotationsUrl, into: ChampionRotationsData.self)
    }

    func champions() async throws -> ChampionsData {
        try await getWithAuth(from: championsDataUrl, into: ChampionsData.self)
    }

    private func getWithAuth<T>(from url: String, into type: T.Type) async throws -> T
    where T: Decodable {
        try await http.get(from: url, into: type, with: ["X-Riot-Token": apiKey])
    }
}

extension RiotApiClient {
    private var platform: String { "eun1" }
    private var version: String { "14.14.1" }

    private var championRotationsUrl: String {
        "https://\(platform).api.riotgames.com/lol/platform/v3/champion-rotations"
    }
    private var championsDataUrl: String {
        "https://ddragon.leagueoflegends.com/cdn/\(version)/data/en_US/champion.json"
    }

}

struct ChampionRotationsData: Decodable {
    let freeChampionIds: [Int]
    let freeChampionIdsForNewPlayers: [Int]
    let maxNewPlayerLevel: Int
}

struct ChampionsData: Decodable {
    let data: [String: ChampionData]
}

struct ChampionData: Decodable {
    let id: String
    let key: String
    let name: String
}