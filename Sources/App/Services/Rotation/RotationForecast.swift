import Foundation

protocol RotationForecast: Sendable {
  func predict(champions: [String], rotations: [[String]], previousRotationId: String)
    throws(RotationForecastError) -> [String]
}

struct DefaultRotationForecast: RotationForecast {
  func predict(champions: [String], rotations: [[String]], previousRotationId: String)
    throws(RotationForecastError) -> [String]
  {
    var rng = LinearRandomNumberGenerator(seed: calcSeed(of: previousRotationId))

    let allocation = countAllocation(
      count: try count(rotations: rotations, rng: &rng)
    )

    var champions = champions
    var selection = [String]()

    try selectByInterval(
      count: allocation.interval, from: &champions, into: &selection,
      rotations: rotations, rng: &rng
    )
    try selectByFrequency(
      count: allocation.frequency, from: &champions, into: &selection,
      rotations: rotations, rng: &rng
    )
    selectByRandom(
      count: allocation.random, from: &champions, into: &selection,
      rng: &rng
    )

    return selection.sorted()
  }

  func count(rotations: [[String]], rng: inout some RandomNumberGenerator)
    throws(RotationForecastError) -> Int
  {
    var countOccurrences = [Int: Int]()
    for champions in rotations {
      countOccurrences[champions.count, default: 0] += 1
    }

    var weightsSum = 0.0
    var weights = [Int: Double]()
    for (count, occurrences) in countOccurrences {
      let weight = pow(Double(occurrences), 1.5)
      weights[count] = weight
      weightsSum += weight
    }

    var nextRangeStart = 0.0
    var normalizedWeights = [(Range<Double>, Int)]()
    for (count, weight) in weights.sorted(by: \.key) {
      let normalizedWeight = weight / weightsSum
      let range = nextRangeStart..<nextRangeStart + normalizedWeight
      normalizedWeights.append((range, count))
      nextRangeStart += normalizedWeight
    }

    let weight = rng.nextFraction()
    let selection = normalizedWeights.first { (range, _) in range.contains(weight) }
    guard let selection else {
      throw .invalidCountWeight
    }
    return selection.1
  }

  func countAllocation(count: Int) -> RotationCountAllocation {
    let interval = Int(round(Double(count) * 0.6))
    let frequency = Int(round(Double(count) * 0.3))
    let random = count - interval - frequency

    return RotationCountAllocation(
      interval: interval,
      frequency: frequency,
      random: random
    )
  }

  /// Selects and moves a specified number of champions from the available into
  /// the selected list based on how close each champion is to its most frequent
  /// interval between consecutive rotations.
  func selectByInterval(
    count: Int, from available: inout [String], into selected: inout [String],
    rotations: [[String]], rng: inout some RandomNumberGenerator
  ) throws(RotationForecastError) {
    let isAvailable = Set(available).contains
    var rotationNumbers = [String: [Int]]()
    for champion in available {
      rotationNumbers[champion] = [0]
    }
    for (index, rotation) in rotations.reversed().enumerated() {
      for champion in rotation.filter(isAvailable) {
        rotationNumbers[champion, default: [0]].append(index + 1)
      }
    }

    var mostFrequentIntervals = [String: Int]()
    for (champion, rotations) in rotationNumbers.sorted(by: \.key) {
      let interval = rotations.adjacentPairs()
        .map { previous, next in next - previous }
        .mostFrequent(using: &rng)
      mostFrequentIntervals[champion] = interval
    }

    return try selectByWeights(
      count: count, from: &available, into: &selected, rng: &rng
    ) { champion in
      guard let interval = mostFrequentIntervals[champion] else {
        return 0
      }
      let mostRecentRotation = rotationNumbers[champion]?.last ?? 0
      let currentInterval = rotations.count - mostRecentRotation
      return 1.0 / Double((1 + abs(interval - currentInterval)))
    }
  }

  /// Selects and moves a specified number of champions from the available into
  /// the selected list based on champion's frequency in previous rotations.
  func selectByFrequency(
    count: Int, from available: inout [String], into selected: inout [String],
    rotations: [[String]], rng: inout some RandomNumberGenerator
  ) throws(RotationForecastError) {
    let isAvailable = Set(available).contains
    var occurrences = [String: Int]()
    for rotation in rotations {
      for champion in rotation.filter(isAvailable) {
        occurrences[champion, default: 0] += 1
      }
    }

    return try selectByWeights(
      count: count, from: &available, into: &selected,
      rng: &rng
    ) { champion in
      guard let occurrences = occurrences[champion] else {
        return 0
      }
      return pow(Double(occurrences), 1)
    }
  }

  /// Selects and moves a specified number of champions from the available into
  /// the selected list based on a random selection.
  func selectByRandom(
    count: Int, from available: inout [String], into selected: inout [String],
    rng: inout some RandomNumberGenerator
  ) {
    for _ in 0..<count {
      let index = Int.random(in: 0..<available.count, using: &rng)
      let champion = available.remove(at: index)
      selected.append(champion)
    }
  }

  private func selectByWeights(
    count: Int, from available: inout [String], into selected: inout [String],
    rng: inout some RandomNumberGenerator, weightFor: (String) -> Double
  ) throws(RotationForecastError) {
    var weights = [String: Double]()
    for champion in available {
      weights[champion] = weightFor(champion)
    }

    func calcNormalizedWeights(_ weights: [String: Double]) -> [(Range<Double>, String)] {
      let weightsSum = weights.values.reduce(0, +)
      var nextRangeStart = 0.0
      var normalized = [(Range<Double>, String)]()
      for (champion, weight) in weights.sorted(by: \.key) {
        let normalizedWeight = Double(weight) / Double(weightsSum)
        let range = nextRangeStart..<nextRangeStart + normalizedWeight
        normalized.append((range, champion))
        nextRangeStart += normalizedWeight
      }
      return normalized
    }

    var availableWeights = weights
    for _ in 0..<count {
      let normalizedWeights = calcNormalizedWeights(availableWeights)
      let weight = rng.nextFraction()
      let champion = normalizedWeights.first { (range, _) in range.contains(weight) }?.1
      guard let champion, let indexToRemove = available.firstIndex(of: champion) else {
        throw .invalidChampionWeight
      }
      available.remove(at: indexToRemove)
      selected.append(champion)
      availableWeights.removeValue(forKey: champion)
    }
  }
}

enum RotationForecastError: Error {
  case invalidCountWeight
  case invalidChampionWeight
}

struct RotationCountAllocation {
  let interval: Int
  let frequency: Int
  let random: Int
}

extension RandomNumberGenerator {
  fileprivate mutating func nextFraction() -> Double {
    Double.random(in: 0..<1, using: &self)
  }
}
