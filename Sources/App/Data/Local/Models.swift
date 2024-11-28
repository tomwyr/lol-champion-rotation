import Fluent
import Foundation

final class ChampionModel: Model, @unchecked Sendable {
  static let schema = "champions"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "riot_id")
  var riotId: String

  @Field(key: "name")
  var name: String

  init() {}

  init(id: UUID? = nil, riotId: String, name: String) {
    self.id = id
    self.riotId = riotId
    self.name = name
  }
}

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

extension ChampionModel {
  convenience init(championData: ChampionData) {
    self.init(riotId: championData.id, name: championData.name)
  }
}

extension Collection<ChampionData> {
  func toModels() -> [ChampionModel] {
    map { .init(championData: $0) }
  }
}

final class PatchVersionModel: Model, @unchecked Sendable {
  static let schema = "patch-versions"

  @ID(key: .id)
  var id: UUID?

  @Timestamp(key: "observed_at", on: .create)
  var observedAt: Date?

  @Field(key: "value")
  var value: String?

  init() {}

  init(value: String) {
    self.value = value
  }
}
