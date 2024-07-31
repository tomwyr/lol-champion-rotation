import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

struct RiotApiClient {
    let apiKey: String

    func championRotations() async throws -> ChampionRotationsData {
        try await requestWithAuth(from: championRotationsUrl, into: ChampionRotationsData.self)
    }

    func champions() async throws -> ChampionsData {
        try await requestWithAuth(from: championsDataUrl, into: ChampionsData.self)
    }

    private func requestWithAuth<T>(from url: String, into type: T.Type) async throws -> T
    where T: Decodable {
        try await request(from: url, into: type, with: ["X-Riot-Token": apiKey])
    }

    private func request<T>(
        from url: String,
        into type: T.Type,
        with headers: [String: String] = [String: String]()
    ) async throws -> T where T: Decodable {
        let request = URLRequest(url: url, headers: headers)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard response.isHttpSuccess() else {
            throw RiotApiClientError.unexpectedResponse(response)
        }
        return try JSONDecoder().decode(type.self, from: data)
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

extension URLRequest {
    init(url: String, headers: [String: String]) {
        self.init(url: URL(string: url)!)
        for (key, value) in headers {
            self.addValue(value, forHTTPHeaderField: key)
        }
    }
}

extension URLResponse {
    func isHttpSuccess() -> Bool {
        if let response = self as? HTTPURLResponse, 200..<300 ~= response.statusCode {
            return true
        }
        return false
    }
}

enum RiotApiClientError: Error {
    case unexpectedResponse(URLResponse)
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
