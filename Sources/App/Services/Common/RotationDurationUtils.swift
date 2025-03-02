import Foundation

protocol RotationDurationService {
  associatedtype OutError: Error

  var appDatabase: AppDatabase { get }

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
    guard let endDate = nextRotationDate ?? startDate.adding(1, .weekOfYear) else {
      throw wrapError(.endDateInvalid)
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
      let nextRotation = try await appDatabase.findNextRegularRotation(after: rotationId)
      return nextRotation?.observedAt
    } catch {
      throw wrapError(.dataOperationFailed(cause: error))
    }
  }
}

enum RotationDurationError: Error {
  case endDateInvalid
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
