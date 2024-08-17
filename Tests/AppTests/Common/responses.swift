@testable import App

let requestUrls = (
  riotChampionRotations: "https://eun1.api.riotgames.com/lol/platform/v3/champion-rotations",
  riotChampions: "https://ddragon.leagueoflegends.com/cdn/14.14.1/data/en_US/champion.json",
  b2AuthorizeAccount: "https://api003.backblazeb2.com/b2api/v3/b2_authorize_account",
  b2AuthorizeDownload: "https://api003.backblazeb2.com/b2api/v3/b2_get_download_authorization"
)

extension MockHttpClient {
  @Sendable func respondDefault(_ url: String) -> Any? {
    switch url {
    case requestUrls.riotChampionRotations:
      ChampionRotationsData(
        freeChampionIds: [],
        freeChampionIdsForNewPlayers: [],
        maxNewPlayerLevel: 0
      )

    case requestUrls.riotChampions:
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
