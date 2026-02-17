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
    let overview = try createOverview(
      champion: champion,
      rotationsCount: data.championsRotationsCount,
      championStreak: data.championStreak,
    )
    let history = try await createHistory(
      champion: champion,
      rotationsAfterRelease: data.regularRotationsAfterRelease,
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
    let rotationsAfterRelease = try await appDb.regularRotations(after: releasedAt)
    let currentRegularRotation = try await appDb.currentRegularRotation()
    let currentBeginnerRotation = try await appDb.currentBeginnerRotation()
    let championsRotationsCount = try await appDb.countChampionsRotations()

    var championStreak: ChampionStreakModel? = nil
    // Only compute the streak if release is known as, otherwise, it might produce incorrect results.
    if releasedAt != nil {
      championStreak = try await appDb.championStreak(of: riotId)
    }

    var userWatchlists: UserWatchlistsModel?
    if let userId {
      userWatchlists = try await appDb.userWatchlists(userId: userId)
    }

    return (
      championLatestRegularRotation,
      championLatestBeginnerRotation,
      championRegularRotationsIds,
      rotationsAfterRelease,
      currentRegularRotation,
      currentBeginnerRotation,
      championsRotationsCount,
      championStreak,
      userWatchlists,
    )
  }
}

private typealias ChampionDetailsLocalData = (
  championLatestRegularRotation: RegularChampionRotationModel?,
  championLatestBeginnerRotation: BeginnerChampionRotationModel?,
  championRegularRotationsIds: [UUID],
  regularRotationsAfterRelease: [RegularChampionRotationModel],
  currentRegularRotation: RegularChampionRotationModel?,
  currentBeginnerRotation: BeginnerChampionRotationModel?,
  championsRotationsCount: [ChampionRotationsCountModel],
  championStreak: ChampionStreakModel?,
  userWatchlists: UserWatchlistsModel?
)
