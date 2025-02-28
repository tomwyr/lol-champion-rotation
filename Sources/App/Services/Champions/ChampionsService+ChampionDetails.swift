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
      let regularRotation = try await appDatabase.mostRecentRegularRotation(
        withChampion: championRiotId)
      let beginnerRotation = try await appDatabase.mostRecentBeginnerRotation(
        withChampion: championRiotId)
      let currentRegularRotation = try await appDatabase.currentRegularRotation()
      let currentBeginnerRotation = try await appDatabase.currentBeginnerRotation()
      let championsOccurrences = try await appDatabase.countChampionsOccurrences(of: championRiotId)
      let championStreak = try await appDatabase.championStreak(of: championRiotId)
      return (
        regularRotation, beginnerRotation,
        currentRegularRotation, currentBeginnerRotation,
        championsOccurrences, championStreak
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

    return try championFactory.createDetails(
      riotId: champion.riotId,
      availability: createAvailability(data),
      overview: createOverview(champion, data)
    )
  }

  private func createAvailability(_ data: ChampionDetailsLocalData)
    -> [ChampionDetailsAvailability]
  {
    let (regularRotation, beginnerRotation, currentRegularRotation, currentBeginnerRotation, _, _) =
      data

    var availability = [ChampionDetailsAvailability]()
    availability.append(
      .init(
        rotationType: .regular,
        lastAvailable: regularRotation?.observedAt,
        current: regularRotation?.id != nil && regularRotation?.id == currentRegularRotation?.id
      ))
    availability.append(
      .init(
        rotationType: .beginner,
        lastAvailable: beginnerRotation?.observedAt,
        current: beginnerRotation?.id != nil
          && beginnerRotation?.id == currentBeginnerRotation?.id
      ))

    return availability
  }

  private func createOverview(_ champion: ChampionModel, _ data: ChampionDetailsLocalData)
    throws(ChampionsError) -> ChampionDetailsOverview
  {
    let (_, _, _, _, championsOccurrences, championStreak) = data

    let dataInvalidOrMissing = ChampionsError.dataInvalidOrMissing(
      championId: champion.id?.uuidString)

    let occurrences =
      championsOccurrences
      .first { group in group.champions.contains(champion.riotId) }?
      .count
    guard let occurrences else {
      throw dataInvalidOrMissing
    }

    let morePopularChampions =
      championsOccurrences
      .filter { group in group.count > occurrences }
      .reduce(0) { result, next in result + next.champions.count }
    let popularity = morePopularChampions + 1

    guard let present = championStreak?.present, let absent = championStreak?.absent,
      (present == 0 && absent > 0) || (present > 0 && absent == 0)
    else {
      throw dataInvalidOrMissing
    }
    let currentStreak = if present > 0 { present } else { -absent }

    return ChampionDetailsOverview(
      occurrences: occurrences,
      popularity: popularity,
      currentStreak: currentStreak
    )
  }
}

private typealias ChampionDetailsLocalData = (
  regularRotation: RegularChampionRotationModel?,
  beginnerRotation: BeginnerChampionRotationModel?,
  currentRegularRotation: RegularChampionRotationModel?,
  currentBeginnerRotation: BeginnerChampionRotationModel?,
  championsOccurrences: [ChampionsOccurrencesModel],
  championStreak: ChampionStreakModel?
)
