import Foundation

extension ChampionsService {
  func championDetails(championId: String) async throws(ChampionsError) -> ChampionDetails? {
    guard let champion = try await loadChampionData(championId) else {
      return nil
    }
    let availavilitiesData = try await loadRotationAvailabilitiesData(champion.riotId)
    let imageUrls = try await getImageUrls([champion])
    return try await createChampionDetails(champion, imageUrls, availavilitiesData)
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

  private func createChampionDetails(
    _ champion: ChampionModel,
    _ imageUrls: ChampionImageUrls,
    _ data: ChampionDetailsLocalData
  )
    async throws(ChampionsError) -> ChampionDetails?
  {
    let championFactory = ChampionFactory(
      champions: [champion],
      imageUrls: imageUrls,
      wrapError: ChampionsError.championError
    )

    return try await championFactory.createDetails(
      riotId: champion.riotId,
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
    guard let currentRotation = data.currentRegularRotation else {
      throw .dataInvalidOrMissing(championId: champion.riotId)
    }

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

  func createBench(_ rotationsMissed: Int) -> ChampionDetailsHistoryEvent {
    .bench(.init(rotationsMissed: rotationsMissed))
  }

  func createRotation(
    _ rotation: RegularChampionRotationModel,
    _ currentRotation: RegularChampionRotationModel,
    _ champion: ChampionModel
  ) async throws(ChampionsError) -> ChampionDetailsHistoryEvent {
    guard let id = rotation.id?.uuidString, let currentId = currentRotation.id?.uuidString else {
      throw .dataInvalidOrMissing(championId: champion.riotId)
    }

    let duration: ChampionRotationDuration
    do {
      duration = try await getRotationDuration(currentRotation)
    } catch {
      // TODO Not accurate error.
      throw .dataOperationFailed(cause: error)
    }

    let championImageUrls: [String]
    let championIds = rotation.champions.prefix(5)
    do {
      championImageUrls = try await imageUrlProvider.champions(with: championIds)
    } catch {
      throw .imagesUnavailable(cause: error)
    }

    return .rotation(
      .init(
        id: id,
        duration: duration,
        current: id == currentId,
        championImageUrls: championImageUrls
      )
    )
  }
}

// TODO Remove rotation service logic duplication.
extension ChampionsService {
  func getRotationDuration(_ rotation: RegularChampionRotationModel)
    async throws(ChampionRotationError) -> ChampionRotationDuration
  {
    let nextRotationDate = try await getNextRotationDate(rotation)
    let startDate = rotation.observedAt
    guard let endDate = nextRotationDate ?? startDate.adding(1, .weekOfYear) else {
      throw .rotationDurationInvalid
    }
    return ChampionRotationDuration(start: startDate, end: endDate)
  }

  func getNextRotationDate(_ rotation: RegularChampionRotationModel)
    async throws(ChampionRotationError) -> Date?
  {
    do {
      guard let rotationId = try? rotation.requireID().uuidString else {
        return nil
      }
      let nextRotation = try await appDatabase.findNextRegularRotation(after: rotationId)
      return nextRotation?.observedAt
    } catch {
      throw .dataOperationFailed(cause: error)
    }
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
