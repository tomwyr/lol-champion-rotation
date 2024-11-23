import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct RiotApiClient {
  let http: HttpClient
  let apiKey: String

  func patchVersions() async throws -> [String] {
    try await getWithAuth(from: patchVersionsUrl, into: [String].self)
  }

  func championRotations() async throws -> ChampionRotationsData {
    try await getWithAuth(from: championRotationsUrl, into: ChampionRotationsData.self)
  }

  func champions(version: String) async throws -> ChampionsData {
    try await getWithAuth(from: championsDataUrl(version), into: ChampionsData.self)
  }

  private func getWithAuth<T>(from url: String, into type: T.Type) async throws -> T
  where T: Decodable {
    try await http.get(from: url, into: type, with: ["X-Riot-Token": apiKey])
  }
}

private let platform = "eun1"

private let patchVersionsUrl = "https://ddragon.leagueoflegends.com/api/versions.json"
private let championRotationsUrl =
  "https://\(platform).api.riotgames.com/lol/platform/v3/champion-rotations"
private func championsDataUrl(_ version: String) -> String {
  "https://ddragon.leagueoflegends.com/cdn/\(version)/data/en_US/champion.json"
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
