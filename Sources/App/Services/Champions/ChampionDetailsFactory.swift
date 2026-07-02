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
    statistics: ChampionHistoryStatisticsModel,
  ) throws -> ChampionDetailsOverview

  func createHistory(
    champion: ChampionModel,
    rotationsAfterRelease: [RegularChampionRotationModel],
    trackedHistoryStartedAt: Date?,
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
    statistics: ChampionHistoryStatisticsModel,
  ) throws -> ChampionDetailsOverview {
    guard statistics.championRiotId == champion.riotId else {
      throw ChampionsError.dataInvalidOrMissing(championId: champion.riotId)
    }

    return ChampionDetailsOverview(
      occurrences: statistics.occurrences,
      popularity: statistics.popularity,
      currentStreak: statistics.currentStreak
    )
  }
}

extension ChampionsService {
  func createHistory(
    champion: ChampionModel,
    rotationsAfterRelease: [RegularChampionRotationModel],
    trackedHistoryStartedAt: Date?,
    currentRotation: RegularChampionRotationModel?,
    featuredRotationsIds: [UUID],
  ) async throws -> [ChampionDetailsHistoryEvent] {
    let calendar = Calendar.gregorianUtc
    var items = [ChampionDetailsHistoryEvent]()

    let eventsByYear = try await createYearGroupedHistory(
      calendar: calendar,
      rotationsAfterRelease: rotationsAfterRelease,
      currentRotation: currentRotation,
      featuredRotationsIds: featuredRotationsIds,
    )
    let eventsOldestYear = eventsByYear.keys.min()

    for (year, events) in eventsByYear.sorted(by: \.key, with: >) {
      items.append(contentsOf: events)
      if year != eventsOldestYear {
        items.append(createYearChanged(year))
      }
    }

    if let releasedAt = champion.releasedAt {
      let releasedBeforeTrackedHistory =
        if let trackedHistoryStartedAt { releasedAt < trackedHistoryStartedAt } else { false }

      let releaseYear = calendar.year(of: releasedAt)
      if let eventsOldestYear, eventsOldestYear != releaseYear {
        items.append(createYearChanged(eventsOldestYear))
      }

      if releasedBeforeTrackedHistory {
        items.append(createGap())
      }
      items.append(createRelease(releasedAt))
    }

    return items
  }

  private func createYearGroupedHistory(
    calendar: Calendar,
    rotationsAfterRelease: [RegularChampionRotationModel],
    currentRotation: RegularChampionRotationModel?,
    featuredRotationsIds: [UUID],
  ) async throws -> [Int: [ChampionDetailsHistoryEvent]] {
    var eventsByYear: [Int: [ChampionDetailsHistoryEvent]] = [:]
    var benchYear: Int?
    var rotationsMissed = 0

    for rotation in rotationsAfterRelease {
      guard let id = rotation.id else { continue }
      let rotationYear = calendar.year(of: rotation.observedAt)

      // Champion not in rotation
      if !featuredRotationsIds.contains(id) {
        // Year ended while on bench
        if let year = benchYear, year != rotationYear {
          eventsByYear.append(in: year, createBench(rotationsMissed))
          rotationsMissed = 0
        }
        benchYear = rotationYear
        rotationsMissed += 1
        continue
      }

      // Bench streak ended
      if let year = benchYear, rotationsMissed > 0 {
        eventsByYear.append(in: year, createBench(rotationsMissed))
        benchYear = nil
        rotationsMissed = 0
      }

      // Champion in rotation
      let historyRotation = try await createHistoryRotation(
        rotation: rotation,
        currentRotation: currentRotation,
      )
      eventsByYear.append(in: rotationYear, .rotation(historyRotation))
    }

    // Currently still on bench
    if let year = benchYear, rotationsMissed > 0 {
      eventsByYear.append(in: year, createBench(rotationsMissed))
    }

    return eventsByYear
  }

  private func createYearChanged(_ year: Int) -> ChampionDetailsHistoryEvent {
    .yearChanged(.init(year: year))
  }

  private func createBench(_ rotationsMissed: Int) -> ChampionDetailsHistoryEvent {
    .bench(.init(rotationsMissed: rotationsMissed))
  }

  private func createGap() -> ChampionDetailsHistoryEvent {
    .gap(.init())
  }

  private func createRelease(_ releasedAt: Date) -> ChampionDetailsHistoryEvent {
    .release(.init(releasedAt: releasedAt))
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

extension [Int: [ChampionDetailsHistoryEvent]] {
  fileprivate mutating func append(in year: Int, _ event: ChampionDetailsHistoryEvent) {
    self[year, default: []].append(event)
  }
}
