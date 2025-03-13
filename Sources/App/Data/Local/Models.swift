import Fluent
import Foundation

final class ChampionModel: Model, @unchecked Sendable {
  static let schema = "champions"

  @ID(key: .id)
  var id: UUID?

  @Timestamp(key: "released_at", on: .none)
  var releasedAt: Date?

  @Field(key: "riot_id")
  var riotId: String

  @Field(key: "name")
  var name: String

  @Field(key: "title")
  var title: String

  init() {}

  init(id: UUID? = nil, releasedAt: Date? = nil, riotId: String, name: String, title: String) {
    self.id = id
    self.releasedAt = releasedAt
    self.riotId = riotId
    self.name = name
    self.title = title
  }
}

/// Deprecated: Champion rotation model was split into regular and beginner rotation models.
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

final class RegularChampionRotationModel: Model, @unchecked Sendable {
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
    champions: [String]
  ) {
    self.id = id
    self.observedAt = observedAt
    self.champions = champions
  }

  func same(as other: RegularChampionRotationModel) -> Bool {
    champions.sorted() == other.champions.sorted()
  }
}

final class BeginnerChampionRotationModel: Model, @unchecked Sendable {
  static let schema = "beginner-champion-rotations"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "observed_at")
  var observedAt: Date

  @Field(key: "max_level")
  var maxLevel: Int

  @Field(key: "champions")
  var champions: [String]

  init() {}

  init(
    id: UUID? = nil,
    observedAt: Date,
    maxLevel: Int,
    champions: [String]
  ) {
    self.id = id
    self.observedAt = observedAt
    self.maxLevel = maxLevel
    self.champions = champions
  }

  func same(as other: BeginnerChampionRotationModel) -> Bool {
    maxLevel == other.maxLevel && champions.sorted() == other.champions.sorted()
  }
}

extension ChampionModel {
  convenience init(championData: ChampionData) {
    self.init(
      riotId: championData.id,
      name: championData.name,
      title: championData.title
    )
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

  init(
    observedAt: Date? = nil,
    value: String
  ) {
    self.observedAt = observedAt
    self.value = value
  }
}

final class NotificationsConfigModel: Model, @unchecked Sendable {
  static let schema = "notifications-configs"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "user_id")
  var userId: String

  @Field(key: "token")
  var token: String

  @Field(key: "enabled")
  var enabled: Bool

  init() {}

  init(userId: String, token: String, enabled: Bool) {
    self.userId = userId
    self.token = token
    self.enabled = enabled
  }
}

struct ChampionRotationsCountModel: Codable {
  let champion: String
  let presentIn: Int
  let afterRelease: Int
  let total: Int
}

struct ChampionStreakModel: Codable {
  let champion: String
  let present: Int
  let absent: Int
}
