import Fluent
import Foundation

extension QueryBuilder where Model == RegularChampionRotationModel {
  func lastYear(instant: Instant = .system) async throws -> [RegularChampionRotationModel] {
    try await filter(\.$active == true)
      .sort(\.$observedAt, .descending)
      .filter(\.$observedAt > instant.now.subtracting(1, .year)!)
      .all()
  }
}
