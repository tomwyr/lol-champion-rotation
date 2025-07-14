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

final class RegularChampionRotationModel: Model, @unchecked Sendable {
  static let schema = "regular-champion-rotations"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "active")
  var active: Bool

  @Field(key: "observed_at")
  var observedAt: Date

  @Field(key: "champions")
  var champions: [String]

  @Field(key: "slug")
  var slug: String

  init() {}

  init(
    id: UUID? = nil,
    active: Bool = true,
    observedAt: Date,
    champions: [String],
    slug: String,
  ) {
    self.id = id
    self.active = active
    self.observedAt = observedAt
    self.champions = champions
    self.slug = slug
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

  @Field(key: "rotation_changed")
  var rotationChanged: Bool

  @Field(key: "champions_available")
  var championsAvailable: Bool

  init() {}

  init(userId: String, token: String, rotationChanged: Bool, championsAvailable: Bool) {
    self.userId = userId
    self.token = token
    self.rotationChanged = rotationChanged
    self.championsAvailable = championsAvailable
  }
}

final class UserWatchlistsModel: Model, @unchecked Sendable {
  static let schema = "user-watchlists"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "user_id")
  var userId: String

  @Field(key: "rotations")
  var rotations: [String]

  @Field(key: "champions")
  var champions: [String]

  init() {}

  init(userId: String, rotations: [String] = [], champions: [String] = []) {
    self.userId = userId
    self.rotations = rotations
    self.champions = champions
  }
}

final class ChampionRotationPredictionModel: Model, @unchecked Sendable {
  static let schema = "champion-rotation-predictions"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "ref_rotation_id")
  var refRotationId: UUID

  @Field(key: "champions")
  var champions: [String]

  init() {}

  init(refRotationId: UUID, champions: [String]) {
    self.refRotationId = refRotationId
    self.champions = champions
  }
}

struct ChampionRotationsCountModel: Codable {
  let champion: String
  let presentIn: Int
  let afterRelease: Int?
  let total: Int
}

struct ChampionStreakModel: Codable {
  let champion: String
  let present: Int
  let absent: Int
}
