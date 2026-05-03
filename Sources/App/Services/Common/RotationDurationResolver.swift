import Foundation

protocol RotationDurationResolver {
  var appDb: AppDatabase { get }

  func getRotationDuration(
    _ rotation: RegularChampionRotationModel,
  ) async throws -> ChampionRotationDuration

  func getRotationDurations(
    _ rotations: [RegularChampionRotationModel],
  ) async throws -> [ChampionRotationDuration]
}

extension RotationDurationResolver {
  func getRotationDuration(
    _ rotation: RegularChampionRotationModel,
  ) async throws -> ChampionRotationDuration {
    let changeWeekday = try await getRotationChangeWeekday()
    let startDate = rotation.observedAt

    let endDate =
      if let nextStart = try await getNextRotationDate(rotation) {
        nextStart
      } else if let expectedEnd = try getRotationExpectedEndDate(startDate, changeWeekday) {
        expectedEnd
      } else {
        throw RotationDurationError.computedDateInvalid
      }

    return ChampionRotationDuration(start: startDate, end: endDate)
  }

  func getRotationDurations(
    _ rotations: [RegularChampionRotationModel],
  ) async throws -> [ChampionRotationDuration] {
    let changeWeekday = try await getRotationChangeWeekday()

    var result = [ChampionRotationDuration]()

    for index in rotations.indices {
      // Rotation is `next` chronologically but `previous` from the array point of view.
      let (nextRotation, rotation) = (rotations[try: index - 1], rotations[index])

      let startDate = rotation.observedAt

      let endDate =
        if let nextStart = try await getNextRotationDate(rotation, nextRotation) {
          nextStart
        } else if let expectedEnd = try getRotationExpectedEndDate(startDate, changeWeekday) {
          expectedEnd
        } else {
          throw RotationDurationError.computedDateInvalid
        }

      let duration = ChampionRotationDuration(start: startDate, end: endDate)
      result.append(duration)
    }

    return result
  }

  func getRotationPredictionDuration(
    _ currentRotation: RegularChampionRotationModel,
  ) async throws -> ChampionRotationDuration {
    let changeWeekday = try await getRotationChangeWeekday()
    guard let startDate = try getRotationExpectedEndDate(currentRotation.observedAt, changeWeekday),
      let endDate = try getRotationExpectedEndDate(startDate, changeWeekday)
        ?? startDate.adding(1, .weekOfYear)
    else {
      throw RotationDurationError.computedDateInvalid
    }
    return ChampionRotationDuration(start: startDate, end: endDate)
  }

  private func getNextRotationDate(
    _ rotation: RegularChampionRotationModel,
    _ nextRotation: RegularChampionRotationModel? = nil,
  ) async throws -> Date? {
    if let nextRotation {
      return nextRotation.observedAt
    }

    guard let rotationId = rotation.idString else { return nil }
    let nextRotation = try await appDb.findNextRegularRotation(after: rotationId)
    return nextRotation?.observedAt
  }

  private func getRotationExpectedEndDate(_ startDate: Date, _ changeWeekday: Int) throws -> Date? {
    guard 1...7 ~= changeWeekday else {
      throw RotationDurationError.rotationChangeWeekdayInvalid(weekday: changeWeekday)
    }
    let swiftChangeWeekday = (changeWeekday + 1) % 7
    return startDate.advancedToNext(weekday: swiftChangeWeekday)?.withTime(of: startDate)
  }

  private func getRotationChangeWeekday() async throws -> Int {
    let configs = try await appDb.rotationConfigs()
    if configs.count > 1 {
      throw RotationDurationError.rotationConfigAmbiguous
    }
    guard let config = configs.first else {
      throw RotationDurationError.rotationConfigMissing
    }
    return config.rotationChangeWeekday
  }
}

enum RotationDurationError: Error {
  case computedDateInvalid
  case rotationConfigMissing
  case rotationConfigAmbiguous
  case rotationChangeWeekdayInvalid(weekday: Int)
}

extension ChampionsService: RotationDurationResolver {}

extension DefaultRotationService: RotationDurationResolver {}
