import Foundation

extension ChampionsService {
  func championDetails(championId: String) async throws(ChampionsError) -> ChampionDetails? {
    guard let champion = try await loadChampionData(championId) else {
      return nil
    }
    let availabilitiesData = try await loadRotationAvailabilitiesData(champion)
    return try await createChampionDetails(champion, availabilitiesData)
  }

  private func loadChampionData(_ championId: String) async throws(ChampionsError) -> ChampionModel?
  {
    do {
      return try await appDatabase.champion(id: championId)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  private func loadRotationAvailabilitiesData(_ champion: ChampionModel)
    async throws(ChampionsError) -> ChampionDetailsLocalData
  {
    let riotId = champion.riotId
    let releasedAt = champion.releasedAt

    do {
      let championLatestRegularRotation = try await appDatabase.mostRecentRegularRotation(
        withChampion: riotId)
      let championLatestBeginnerRotation = try await appDatabase.mostRecentBeginnerRotation(
        withChampion: riotId)
      let championRegularRotationsIds = try await appDatabase.regularRotationsIds(
        withChampion: riotId)
      let rotationsAfterRelease = try await appDatabase.regularRotations(after: releasedAt)
      let currentRegularRotation = try await appDatabase.currentRegularRotation()
      let currentBeginnerRotation = try await appDatabase.currentBeginnerRotation()
      let championsRotationsCount = try await appDatabase.countChampionsRotations()
      let championStreak = try await appDatabase.championStreak(of: riotId)
      return (
        championLatestRegularRotation,
        championLatestBeginnerRotation,
        championRegularRotationsIds,
        rotationsAfterRelease,
        currentRegularRotation,
        currentBeginnerRotation,
        championsRotationsCount,
        championStreak
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
    let popularity = calcPopularity(champion, data)

    guard let present = championStreak?.present, let absent = championStreak?.absent,
      present == 0 || absent == 0
    else {
      throw .dataInvalidOrMissing(championId: champion.riotId)
    }
    let currentStreak = if present > 0 { present } else if absent > 0 { -absent } else { 0 }

    return ChampionDetailsOverview(
      occurrences: occurrences,
      popularity: popularity,
      currentStreak: currentStreak
    )
  }

  private func calcPopularity(_ champion: ChampionModel, _ data: ChampionDetailsLocalData) -> Int {
    let rotationsCount = data.championsRotationsCount

    var championScore = 0.0
    var scores = [Double]()
    for count in rotationsCount {
      let relativeScore = Double(count.presentIn) / Double(count.afterRelease)
      let globalScore = Double(count.presentIn) / Double(count.total)
      let score = 0.5 * relativeScore + 0.5 * globalScore
      scores.append(score)
      if count.champion == champion.riotId {
        championScore = score
      }
    }

    return scores.count { $0 > championScore } + 1
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
  championStreak: ChampionStreakModel?
)
