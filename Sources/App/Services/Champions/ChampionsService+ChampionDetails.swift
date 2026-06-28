import Foundation

extension ChampionsService {
  func championDetails(riotId: String, userId: String?) async throws -> ChampionDetails? {
    guard let champion = try await appDb.champion(riotId: riotId) else {
      return nil
    }
    let data = try await loadRotationAvailabilitiesData(champion, userId)

    let availability = createAvailability(
      championRegularRotation: data.championLatestRegularRotation,
      championBeginnerRotation: data.championLatestBeginnerRotation,
      currentRegularRotation: data.currentRegularRotation,
      currentBeginnerRotation: data.currentBeginnerRotation,
    )

    let overview: ChampionDetailsOverview? =
      if let statistics = data.statistics {
        try createOverview(champion: champion, statistics: statistics)
      } else {
        nil
      }

    let history = try await createHistory(
      champion: champion,
      rotationsAfterRelease: data.regularRotationsAfterRelease,
      trackedHistoryStartedAt: data.regularRotations.map(\.observedAt).min(),
      currentRotation: data.currentRegularRotation,
      featuredRotationsIds: data.championRegularRotationsIds,
    )

    return try createChampionDetails(
      model: champion,
      userWatchlists: data.userWatchlists,
      availability: availability,
      overview: overview,
      history: history,
    )
  }

  private func loadRotationAvailabilitiesData(
    _ champion: ChampionModel, _ userId: String?,
  ) async throws -> ChampionDetailsLocalData {
    let riotId = champion.riotId
    let releasedAt = champion.releasedAt

    let championLatestRegularRotation =
      try await appDb.mostRecentRegularRotation(withChampion: riotId)
    let championLatestBeginnerRotation =
      try await appDb.mostRecentBeginnerRotation(withChampion: riotId)
    let championRegularRotationsIds = try await appDb.regularRotationsIds(withChampion: riotId)
    let regularRotations = try await appDb.regularRotations()
    let rotationsAfterRelease =
      if let releasedAt {
        regularRotations.filter { $0.observedAt > releasedAt }
      } else {
        regularRotations
      }
    let currentRegularRotation = try await appDb.currentRegularRotation()
    let currentBeginnerRotation = try await appDb.currentBeginnerRotation()
    let statistics = try? await appDb.championHistoryStatistics(championRiotId: champion.riotId)

    var userWatchlists: UserWatchlistsModel?
    if let userId {
      userWatchlists = try await appDb.userWatchlists(userId: userId)
    }

    return (
      championLatestRegularRotation,
      championLatestBeginnerRotation,
      championRegularRotationsIds,
      rotationsAfterRelease,
      regularRotations,
      currentRegularRotation,
      currentBeginnerRotation,
      statistics,
      userWatchlists,
    )
  }
}

private typealias ChampionDetailsLocalData = (
  championLatestRegularRotation: RegularChampionRotationModel?,
  championLatestBeginnerRotation: BeginnerChampionRotationModel?,
  championRegularRotationsIds: [UUID],
  regularRotationsAfterRelease: [RegularChampionRotationModel],
  regularRotations: [RegularChampionRotationModel],
  currentRegularRotation: RegularChampionRotationModel?,
  currentBeginnerRotation: BeginnerChampionRotationModel?,
  statistics: ChampionHistoryStatisticsModel?,
  userWatchlists: UserWatchlistsModel?
)
