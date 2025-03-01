extension ChampionDetailsHistoryEvent {
  private enum CodingKeys: String, CodingKey {
    case type
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)
    self =
      switch type {
      case "rotation":
        try .rotation(ChampionDetailsHistoryRotation(from: decoder))
      case "bench":
        try .bench(ChampionDetailsHistoryBench(from: decoder))
      default:
        throw DecodingError.dataCorruptedError(
          forKey: CodingKeys.type, in: container,
          debugDescription: "Unknown or missing ChampionDetailsHistoryEvent type: \(type)'"
        )
      }
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .rotation(let value):
      try container.encode("rotation", forKey: .type)
      try value.encode(to: encoder)
    case .bench(let value):
      try container.encode("bench", forKey: .type)
      try value.encode(to: encoder)
    }
  }
}
