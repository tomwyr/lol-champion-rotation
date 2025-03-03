import Foundation

extension ChampionsService {
  func championDetails(championId: String) async throws(ChampionsError) -> ChampionDetails? {
    guard let champion = try await loadChampionData(championId) else {
      return nil
    }
    let availavilitiesData = try await loadRotationAvailabilitiesData(champion.riotId)
    return try await createChampionDetails(champion, availavilitiesData)
  }

  private func loadChampionData(_ championId: String) async throws(ChampionsError) -> ChampionModel?
  {
    do {
      return try await appDatabase.champion(id: championId)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  private func loadRotationAvailabilitiesData(_ championRiotId: String) async throws(ChampionsError)
    -> ChampionDetailsLocalData
  {
    do {
      let championLatestRegularRotation = try await appDatabase.mostRecentRegularRotation(
        withChampion: championRiotId)
      let championLatestBeginnerRotation = try await appDatabase.mostRecentBeginnerRotation(
        withChampion: championRiotId)
      let championRegularRotationsIds = try await appDatabase.regularRotationsIds(
        withChampion: championRiotId)
      let regularRotations = try await appDatabase.regularRotations()
      let currentRegularRotation = try await appDatabase.currentRegularRotation()
      let currentBeginnerRotation = try await appDatabase.currentBeginnerRotation()
      let championsOccurrences = try await appDatabase.countChampionsOccurrences(of: championRiotId)
      let championStreak = try await appDatabase.championStreak(of: championRiotId)
      return (
        championLatestRegularRotation,
        championLatestBeginnerRotation,
        championRegularRotationsIds,
        regularRotations,
        currentRegularRotation,
        currentBeginnerRotation,
        championsOccurrences,
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
    let championsOccurrences = data.championsOccurrences
    let championStreak = data.championStreak

    let occurrences =
      championsOccurrences
      .first { group in group.champions.contains(champion.riotId) }?
      .count ?? 0

    let morePopularChampions =
      championsOccurrences
      .filter { group in group.count > occurrences }
      .reduce(0) { result, next in result + next.champions.count }
    let popularity = morePopularChampions + 1

    guard let present = championStreak?.present, let absent = championStreak?.absent,
      present == 0 || absent == 0
    else {
      throw .dataInvalidOrMissing(championId: champion.riotId)
    }
    let currentStreak = if present > 0 { present } else { -absent }

    return ChampionDetailsOverview(
      occurrences: occurrences,
      popularity: popularity,
      currentStreak: currentStreak
    )
  }

  private func createHistory(_ champion: ChampionModel, _ data: ChampionDetailsLocalData)
    async throws(ChampionsError) -> [ChampionDetailsHistoryEvent]
  {
    let allRotations = data.regularRotations
    let championRotationsIds = data.championRegularRotationsIds.uniqued()
    let currentRotation = data.currentRegularRotation

    var items = [ChampionDetailsHistoryEvent]()
    var rotationsMissed = 0

    for rotation in allRotations {
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

    return items
  }

  private func createBench(_ rotationsMissed: Int) -> ChampionDetailsHistoryEvent {
    .bench(.init(rotationsMissed: rotationsMissed))
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
  regularRotations: [RegularChampionRotationModel],
  currentRegularRotation: RegularChampionRotationModel?,
  currentBeginnerRotation: BeginnerChampionRotationModel?,
  championsOccurrences: [ChampionsOccurrencesModel],
  championStreak: ChampionStreakModel?
)
