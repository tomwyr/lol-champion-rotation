import Foundation

protocol RotationDurationService {
  associatedtype OutError: Error

  var appDb: AppDatabase { get }

  func getRotationDuration(_ rotation: RegularChampionRotationModel)
    async throws(OutError) -> ChampionRotationDuration

  func wrapError(_ error: RotationDurationError) -> OutError
}

extension RotationDurationService {
  func getRotationDuration(_ rotation: RegularChampionRotationModel)
    async throws(OutError) -> ChampionRotationDuration
  {
    let changeWeekday = try await getRotationChangeWeekday()
    let startDate = rotation.observedAt

    let endDate =
      if let nextStart = try await getNextRotationDate(rotation) {
        nextStart
      } else if let expectedEnd = try getRotationExpectedEndDate(startDate, changeWeekday) {
        expectedEnd
      } else {
        throw wrapError(.computedDateInvalid)
      }

    return ChampionRotationDuration(start: startDate, end: endDate)
  }

  func getRotationPredictionDuration(_ currentRotation: RegularChampionRotationModel)
    async throws(OutError) -> ChampionRotationDuration
  {
    let changeWeekday = try await getRotationChangeWeekday()
    guard let startDate = try getRotationExpectedEndDate(currentRotation.observedAt, changeWeekday),
      let endDate = try getRotationExpectedEndDate(startDate, changeWeekday) ?? startDate.adding(1, .weekOfYear)
    else {
      throw wrapError(.computedDateInvalid)
    }
    return ChampionRotationDuration(start: startDate, end: endDate)
  }

  private func getNextRotationDate(_ rotation: RegularChampionRotationModel)
    async throws(OutError) -> Date?
  {
    do {
      guard let rotationId = try? rotation.requireID().uuidString else {
        return nil
      }
      let nextRotation = try await appDb.findNextRegularRotation(after: rotationId)
      return nextRotation?.observedAt
    } catch {
      throw wrapError(.dataOperationFailed(cause: error))
    }
  }

  private func getRotationExpectedEndDate(
    _ startDate: Date, _ changeWeekday: Int,
  ) throws(OutError) -> Date? {
    guard 1...7 ~= changeWeekday else {
      throw wrapError(.rotationChangeWeekdayInvalid(weekday: changeWeekday))
    }
    let swiftChangeWeekday = (changeWeekday + 1) % 7
    return startDate.advancedToNext(weekday: swiftChangeWeekday)?.withTime(of: startDate)
  }

  private func getRotationChangeWeekday() async throws(OutError) -> Int {
    let configs: [ChampionRotationConfigModel]
    do {
      configs = try await appDb.rotationConfigs()
    } catch {
      throw wrapError(.dataOperationFailed(cause: error))
    }
    if configs.count > 1 {
      throw wrapError(.rotationConfigAmbiguous)
    }
    guard let config = configs.first else {
      throw wrapError(.rotationConfigMissing)
    }
    return config.rotationChangeWeekday
  }
}

enum RotationDurationError: Error {
  case computedDateInvalid
  case dataOperationFailed(cause: any Error)
  case rotationConfigMissing
  case rotationConfigAmbiguous
  case rotationChangeWeekdayInvalid(weekday: Int)
}

extension ChampionsService: RotationDurationService {
  func wrapError(_ error: RotationDurationError) -> ChampionsError {
    .rotationDurationError(cause: error)
  }
}

extension DefaultRotationService: RotationDurationService {
  func wrapError(_ error: RotationDurationError) -> ChampionRotationError {
    .rotationDurationError(cause: error)
  }
}
