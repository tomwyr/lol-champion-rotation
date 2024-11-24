@testable import App

let defaultPatchVersion = "1.0.0"

let requestUrls = (
  riotPatchVersions: "https://ddragon.leagueoflegends.com/api/versions.json",
  riotChampionRotations: "https://eun1.api.riotgames.com/lol/platform/v3/champion-rotations",
  riotChampions: { @Sendable (version: String) -> String in
    "https://ddragon.leagueoflegends.com/cdn/\(version)/data/en_US/champion.json"
  },
  b2AuthorizeAccount: "https://api003.backblazeb2.com/b2api/v3/b2_authorize_account",
  b2AuthorizeDownload: "https://api003.backblazeb2.com/b2api/v3/b2_get_download_authorization"
)

extension MockHttpClient {
  @Sendable func respondDefault(_ url: String) -> Any? {
    switch url {
    case requestUrls.riotPatchVersions:
      [defaultPatchVersion]

    case requestUrls.riotChampionRotations:
      ChampionRotationsData(
        freeChampionIds: [],
        freeChampionIdsForNewPlayers: [],
        maxNewPlayerLevel: 0
      )

    case requestUrls.riotChampions(defaultPatchVersion):
      ChampionsData(data: [:])

    case requestUrls.b2AuthorizeAccount:
      AuthorizationData(authorizationToken: "")

    case requestUrls.b2AuthorizeDownload:
      AuthorizationData(authorizationToken: "")

    default:
      nil
    }
  }
}
