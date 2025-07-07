import Fluent
import Foundation

/// Deprecated: Replaced by separate regular and beginner rotation models.
final class ChampionRotationModel: Model, @unchecked Sendable {
  static let schema = "champion-rotations"

  @ID(key: .id)
  var id: UUID?

  @Timestamp(key: "observed_at", on: .create)
  var observedAt: Date?

  @Field(key: "beginner_max_level")
  var beginnerMaxLevel: Int

  @Field(key: "beginner_champions")
  var beginnerChampions: [String]

  @Field(key: "regular_champions")
  var regularChampions: [String]

  init() {}

  init(
    observedAt: Date? = nil,
    beginnerMaxLevel: Int,
    beginnerChampions: [String],
    regularChampions: [String]
  ) {
    self.observedAt = observedAt
    self.beginnerMaxLevel = beginnerMaxLevel
    self.beginnerChampions = beginnerChampions
    self.regularChampions = regularChampions
  }
}

/// Deprecated: Replaced by a model that includes a slug.
final class OldRegularChampionRotationModel: Model, @unchecked Sendable {
  static let schema = "regular-champion-rotations"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "observed_at")
  var observedAt: Date

  @Field(key: "champions")
  var champions: [String]

  init() {}

  init(
    id: UUID? = nil,
    observedAt: Date,
    champions: [String],
  ) {
    self.id = id
    self.observedAt = observedAt
    self.champions = champions
  }

  func same(as other: OldRegularChampionRotationModel) -> Bool {
    champions.sorted() == other.champions.sorted()
  }
}
