import Fluent
import Foundation

final class ChampionRotationModel: Model {
  static let schema = "champion-rotations"

  @ID(key: .id)
  var id: UUID?

  @Timestamp(key: "observed_at", on: .create)
  var observedAt: Date?

  @Field(key: "champion_ids")
  var championIds: [String]

  init() {}

  init(championIds: [String]) {
    self.championIds = championIds
  }
}
