struct SeededSelector {
  let seed: Int?

  init(seed: Int? = nil) {
    self.seed = seed
  }

  func select(from elements: [String], taking limit: Int) -> [String] {
    let seed = calcSeed(of: elements, seed: seed.flatMap(String.init))
    var generator = LinearRandomNumberGenerator(seed: seed)
    let shuffled = elements.shuffled(using: &generator)
    return Array(shuffled.prefix(limit))
  }
}
