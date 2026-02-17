import Foundation

protocol ChampionDetailsFactory {
  func createAvailability(
    championRegularRotation: RegularChampionRotationModel?,
    championBeginnerRotation: BeginnerChampionRotationModel?,
    currentRegularRotation: RegularChampionRotationModel?,
    currentBeginnerRotation: BeginnerChampionRotationModel?,
  ) -> [ChampionDetailsAvailability]

  func createOverview(
    champion: ChampionModel,
    rotationsCount: [ChampionRotationsCountModel],
    championStreak: ChampionStreakModel?,
  ) throws -> ChampionDetailsOverview

  func createHistory(
    champion: ChampionModel,
    rotationsAfterRelease: [RegularChampionRotationModel],
    currentRotation: RegularChampionRotationModel?,
    featuredRotationsIds: [UUID],
  ) async throws -> [ChampionDetailsHistoryEvent]
}

extension ChampionsService: ChampionDetailsFactory {}

extension ChampionsService {
  func createAvailability(
    championRegularRotation: RegularChampionRotationModel?,
    championBeginnerRotation: BeginnerChampionRotationModel?,
    currentRegularRotation: RegularChampionRotationModel?,
    currentBeginnerRotation: BeginnerChampionRotationModel?,
  ) -> [ChampionDetailsAvailability] {
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
}

extension ChampionsService {
  func createOverview(
    champion: ChampionModel,
    rotationsCount: [ChampionRotationsCountModel],
    championStreak: ChampionStreakModel?,
  ) throws -> ChampionDetailsOverview {
    let occurrences = rotationsCount.first { $0.champion == champion.riotId }?.presentIn ?? 0
    let popularity = try? ChampionPopularity().calculate(for: champion, data: rotationsCount)

    var currentStreak: Int? = nil
    if let championStreak {
      let (present, absent) = (championStreak.present, championStreak.absent)
      guard present == 0 || absent == 0 else {
        throw ChampionsError.dataInvalidOrMissing(championId: champion.riotId)
      }
      currentStreak = if present > 0 { present } else if absent > 0 { -absent } else { 0 }
    }

    return ChampionDetailsOverview(
      occurrences: occurrences,
      popularity: popularity,
      currentStreak: currentStreak
    )
  }
}

extension ChampionsService {
  func createHistory(
    champion: ChampionModel,
    rotationsAfterRelease: [RegularChampionRotationModel],
    currentRotation: RegularChampionRotationModel?,
    featuredRotationsIds: [UUID],
  ) async throws -> [ChampionDetailsHistoryEvent] {
    var items = [ChampionDetailsHistoryEvent]()
    var rotationsMissed = 0

    for rotation in rotationsAfterRelease {
      guard let id = rotation.id else { continue }

      if !featuredRotationsIds.contains(id) {
        rotationsMissed += 1
        continue
      }

      if rotationsMissed > 0 {
        items.append(createBench(rotationsMissed))
        rotationsMissed = 0
      }
      try await items.append(createRotation(rotation, currentRotation))
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
  ) async throws -> ChampionDetailsHistoryEvent {
    .rotation(
      try await createHistoryRotation(
        rotation: rotation,
        currentRotation: currentRotation,
      )
    )
  }

  private func createHistoryRotation(
    rotation: RegularChampionRotationModel,
    currentRotation: RegularChampionRotationModel?,
  ) async throws -> ChampionDetailsHistoryRotation {
    let id = rotation.slug
    let duration = try await getRotationDuration(rotation)
    let current = rotation.idString == currentRotation?.idString
    let championImageUrls = seededSelector.select(from: rotation.champions, taking: 5)
      .map(imageUrlProvider.champion)

    return .init(
      id: id,
      duration: duration,
      current: current,
      championImageUrls: championImageUrls
    )
  }
}
