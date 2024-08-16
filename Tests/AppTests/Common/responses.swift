@testable import App

@Sendable func mockRespond(url: String) -> Any {
  switch url {
  case "https://eun1.api.riotgames.com/lol/platform/v3/champion-rotations":
    ChampionRotationsData(
      freeChampionIds: [],
      freeChampionIdsForNewPlayers: [],
      maxNewPlayerLevel: 0
    )

  case "https://ddragon.leagueoflegends.com/cdn/14.14.1/data/en_US/champion.json":
    ChampionsData(data: [:])

  case "https://api003.backblazeb2.com/b2api/v3/b2_authorize_account":
    AuthorizationData(authorizationToken: "")

  case "https://api003.backblazeb2.com/b2api/v3/b2_get_download_authorization":
    AuthorizationData(authorizationToken: "")

  default:
    ()
  }
}
