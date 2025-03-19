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
    let nextRotationDate = try await getNextRotationDate(rotation)
    let startDate = rotation.observedAt
    guard let endDate = nextRotationDate ?? startDate.addingExpectedDuration() else {
      throw wrapError(.computedDateInvalid)
    }
    return ChampionRotationDuration(start: startDate, end: endDate)
  }

  func getRotationPredictionDuration(_ currentRotation: RegularChampionRotationModel)
    async throws(OutError) -> ChampionRotationDuration
  {
    guard let startDate = currentRotation.observedAt.addingExpectedDuration(),
      let endDate = startDate.addingExpectedDuration()
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
}

extension Date {
  func addingExpectedDuration() -> Date? {
    adding(1, .weekOfYear)
  }
}

enum RotationDurationError: Error {
  case computedDateInvalid
  case dataOperationFailed(cause: any Error)
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
