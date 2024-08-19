import Fluent
import Foundation

final class ChampionRotationModel: Model {
  static let schema = "champion-rotations"

  @ID(key: .id)
  var id: UUID?

  @Timestamp(key: "observed_at", on: .create)
  var observedAt: Date?

  @Field(key: "beginner_max_level")
  var beginnerMaxLevel: Int

  @Field(key: "beginner_champion_ids")
  var beginnerChampionIds: [String]

  @Field(key: "regular_champion_ids")
  var regularChampionIds: [String]

  init() {}

  init(beginnerMaxLevel: Int, beginnerChampionIds: [String], regularChampionIds: [String]) {
    self.beginnerMaxLevel = beginnerMaxLevel
    self.beginnerChampionIds = beginnerChampionIds
    self.regularChampionIds = regularChampionIds
  }
}

extension ChampionRotationModel {
  convenience init(snapshot: ChampionRotationSnapshot) {
    self.init(
      beginnerMaxLevel: snapshot.beginnerMaxLevel,
      beginnerChampionIds: snapshot.beginnerChampionIds,
      regularChampionIds: snapshot.regularChampionIds
    )
  }

  func toSnapshot() -> ChampionRotationSnapshot {
    .init(
      beginnerMaxLevel: beginnerMaxLevel,
      beginnerChampionIds: beginnerChampionIds,
      regularChampionIds: regularChampionIds
    )
  }
}
