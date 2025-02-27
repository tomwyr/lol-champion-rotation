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
      return (
        regularRotation, beginnerRotation, currentRegularRotation, currentBeginnerRotation
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

    let availability = createAvailability(data)

    return try championFactory.createDetails(
      riotId: champion.riotId,
      availability: availability
    )
  }

  private func createAvailability(_ data: ChampionDetailsLocalData)
    -> [ChampionDetailsAvailability]
  {
    let (regularRotation, beginnerRotation, currentRegularRotation, currentBeginnerRotation) =
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
}

private typealias ChampionDetailsLocalData = (
  regularRotation: RegularChampionRotationModel?,
  beginnerRotation: BeginnerChampionRotationModel?,
  currentRegularRotation: RegularChampionRotationModel?,
  currentBeginnerRotation: BeginnerChampionRotationModel?
)
