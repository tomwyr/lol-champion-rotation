import Foundation

extension ChampionsService {
  func championDetails(championId: String, userId: String?) async throws(ChampionsError)
    -> ChampionDetails?
  {
    guard let champion = try await loadChampionData(championId) else {
      return nil
    }
    let availabilitiesData = try await loadRotationAvailabilitiesData(champion, userId)
    return try await createChampionDetails(champion, availabilitiesData)
  }

  private func loadChampionData(_ championId: String) async throws(ChampionsError) -> ChampionModel?
  {
    do {
      return try await appDb.champion(id: championId)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  private func loadRotationAvailabilitiesData(_ champion: ChampionModel, _ userId: String?)
    async throws(ChampionsError) -> ChampionDetailsLocalData
  {
    let riotId = champion.riotId
    let releasedAt = champion.releasedAt

    do {
      let championLatestRegularRotation = try await appDb.mostRecentRegularRotation(
        withChampion: riotId)
      let championLatestBeginnerRotation = try await appDb.mostRecentBeginnerRotation(
        withChampion: riotId)
      let championRegularRotationsIds = try await appDb.regularRotationsIds(
        withChampion: riotId)
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
        userWatchlists
      )
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  private func createChampionDetails(_ champion: ChampionModel, _ data: ChampionDetailsLocalData)
    async throws(ChampionsError) -> ChampionDetails?
  {
    try await createChampionDetails(
      model: champion,
      userWatchlists: data.userWatchlists,
      availability: createAvailability(data),
      overview: createOverview(champion, data),
      history: createHistory(champion, data)
    )
  }

  private func createAvailability(_ data: ChampionDetailsLocalData)
    -> [ChampionDetailsAvailability]
  {
    let championRegularRotation = data.championLatestRegularRotation
    let championBeginnerRotation = data.championLatestBeginnerRotation
    let currentRegularRotation = data.currentRegularRotation
    let currentBeginnerRotation = data.currentBeginnerRotation

    var availability = [ChampionDetailsAvailability]()
    availability.append(
      .init(
        rotationType: .regular,
        lastAvailable: championRegularRotation?.observedAt,
        current: championRegularRotation?.id != nil
          && championRegularRotation?.id == currentRegularRotation?.id
      ))
    availability.append(
      .init(
        rotationType: .beginner,
        lastAvailable: championBeginnerRotation?.observedAt,
        current: championBeginnerRotation?.id != nil
          && championBeginnerRotation?.id == currentBeginnerRotation?.id
      ))

    return availability
  }

  private func createOverview(_ champion: ChampionModel, _ data: ChampionDetailsLocalData)
    throws(ChampionsError) -> ChampionDetailsOverview
  {
    let rotationsCount = data.championsRotationsCount
    let championStreak = data.championStreak

    let occurrences = rotationsCount.first { $0.champion == champion.riotId }?.presentIn ?? 0
    let popularity = try? ChampionPopularity().calculate(for: champion, data: rotationsCount)

    var currentStreak: Int? = nil
    if let championStreak {
      let (present, absent) = (championStreak.present, championStreak.absent)
      guard present == 0 || absent == 0 else {
        throw .dataInvalidOrMissing(championId: champion.riotId)
      }
      currentStreak = if present > 0 { present } else if absent > 0 { -absent } else { 0 }
    }

    return ChampionDetailsOverview(
      occurrences: occurrences,
      popularity: popularity,
      currentStreak: currentStreak
    )
  }

  private func createHistory(_ champion: ChampionModel, _ data: ChampionDetailsLocalData)
    async throws(ChampionsError) -> [ChampionDetailsHistoryEvent]
  {
    let rotationsAfterRelease = data.regularRotationsAfterRelease
    let championRotationsIds = data.championRegularRotationsIds.uniqued()
    let currentRotation = data.currentRegularRotation

    var items = [ChampionDetailsHistoryEvent]()
    var rotationsMissed = 0

    for rotation in rotationsAfterRelease {
      guard let id = rotation.id else { continue }

      if !championRotationsIds.contains(id) {
        rotationsMissed += 1
        continue
      }

      if rotationsMissed > 0 {
        items.append(createBench(rotationsMissed))
        rotationsMissed = 0
      }
      try await items.append(createRotation(rotation, currentRotation, champion))
    }

    if rotationsMissed > 0 {
      items.append(createBench(rotationsMissed))
      rotationsMissed = 0
    }

    if let releasedAt = champion.releasedAt {
      items.append(createRelease(releasedAt))
    }

    return items
  }

  private func createBench(_ rotationsMissed: Int) -> ChampionDetailsHistoryEvent {
    .bench(.init(rotationsMissed: rotationsMissed))
  }

  private func createRelease(_ releasedAt: Date) -> ChampionDetailsHistoryEvent {
    .release(.init(releasedAt: releasedAt))
  }

  private func createRotation(
    _ rotation: RegularChampionRotationModel,
    _ currentRotation: RegularChampionRotationModel?,
    _ champion: ChampionModel
  ) async throws(ChampionsError) -> ChampionDetailsHistoryEvent {
    guard let id = rotation.idString else {
      throw .dataInvalidOrMissing(championId: champion.riotId)
    }

    let duration = try await getRotationDuration(rotation)
    let current = id == currentRotation?.idString
    let championImageUrls = seededSelector.select(from: rotation.champions, taking: 5)
      .map(imageUrlProvider.champion)

    return .rotation(
      .init(
        id: id,
        duration: duration,
        current: current,
        championImageUrls: championImageUrls
      )
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
