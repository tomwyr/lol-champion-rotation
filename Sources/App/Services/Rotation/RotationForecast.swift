import Foundation

protocol RotationForecast {
  func predict(champions: [String], rotations: [[String]], previousRotationId: String)
    throws(RotationForecastError) -> [String]
}

struct DefaultRotationForecast: RotationForecast {
  func predict(champions: [String], rotations: [[String]], previousRotationId: String)
    throws(RotationForecastError) -> [String]
  {
    let allocation = countAllocation(
      count: try count(
        rotations: rotations,
        seedValue: previousRotationId
      )
    )

    var champions = champions
    var selection = [String]()

    try selectByInterval(
      from: &champions, into: &selection, count: allocation.interval,
      rotations: rotations, seedValue: previousRotationId
    )
    try selectByFrequency(
      from: &champions, into: &selection, count: allocation.frequency,
      rotations: rotations, seedValue: previousRotationId
    )
    selectByRandom(from: &champions, into: &selection, count: allocation.random)

    return selection.sorted()
  }

  func count(rotations: [[String]], seedValue: String) throws(RotationForecastError) -> Int {
    var counts = [Int: Int]()
    for champions in rotations {
      counts[champions.count, default: 0] += 1
    }

    var weightsSum = 0.0
    var countWeights = [Int: Double]()
    for (count, occurrences) in counts {
      let weight = pow(Double(occurrences), 1.5)
      countWeights[count] = weight
      weightsSum += weight
    }

    var nextRangeStart = 0.0
    var normalizedWeights = [(Range<Double>, Int)]()
    for (count, weight) in countWeights {
      let normalizedWeight = weight / weightsSum
      let range = nextRangeStart..<nextRangeStart + normalizedWeight
      normalizedWeights.append((range, count))
      nextRangeStart += normalizedWeight
    }

    var rng = LinearRandomNumberGenerator(seed: calcSeed(of: seedValue))
    let weight = Double(rng.next() % 1000) / 1000
    let selection = normalizedWeights.first { (range, _) in range.contains(weight) }

    guard let count = selection?.1 else {
      throw .unexpected
    }
    return count
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

  func selectByInterval(
    from available: inout [String], into selected: inout [String],
    count: Int, rotations: [[String]], seedValue: String
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
    for (champion, rotations) in rotationNumbers {
      var rng = LinearRandomNumberGenerator(seed: calcSeed(of: seedValue))
      let interval = rotations.zipAdjacent()
        .map { previous, next in next - previous }
        .mostFrequent(using: &rng)
      mostFrequentIntervals[champion] = interval
    }

    var weightsSum = 0.0
    var weights = [String: Double]()
    for (champion, interval) in mostFrequentIntervals {
      let mostRecentRotation = rotationNumbers[champion]?.last ?? 0
      let currentInterval = rotations.count - mostRecentRotation
      let weight = 1.0 / Double((1 + abs(interval - currentInterval)))
      weights[champion] = weight
      weightsSum += weight
    }

    var nextRangeStart = 0.0
    var normalizedWeights = [(Range<Double>, String)]()
    for (champion, weight) in weights.sorted(by: \.key) {
      let normalizedWeight = Double(weight) / Double(weightsSum)
      let range = nextRangeStart..<nextRangeStart + normalizedWeight
      normalizedWeights.append((range, champion))
      nextRangeStart += normalizedWeight
    }

    var availableWeights = normalizedWeights
    var rng = LinearRandomNumberGenerator(seed: calcSeed(of: seedValue))
    for _ in 0..<count {
      var champion: String?
      // TODO Use more efficient way of not reselecting the same champion.
      while champion == nil {
        let weight = Double(rng.next() % 1000) / 1000
        let index = availableWeights.firstIndex { (range, _) in range.contains(weight) }
        if let index {
          champion = availableWeights.remove(at: index).1
        }
      }
      guard let champion, let indexToRemove = available.firstIndex(of: champion) else {
        throw .unexpected
      }
      available.remove(at: indexToRemove)
      selected.append(champion)
    }
  }

  func selectByFrequency(
    from available: inout [String], into selected: inout [String],
    count: Int, rotations: [[String]], seedValue: String
  ) throws(RotationForecastError) {
    let isAvailable = Set(available).contains
    var counts = [String: Int]()
    for rotation in rotations {
      for champion in rotation.filter(isAvailable) {
        counts[champion, default: 0] += 1
      }
    }

    var weightsSum = 0.0
    var weights = [String: Double]()
    for (champion, count) in counts {
      let weight = pow(Double(count), 1)
      weights[champion, default: 0] = weight
      weightsSum += weight
    }

    var nextRangeStart = 0.0
    var normalizedWeights = [(Range<Double>, String)]()
    for (champion, weight) in weights.sorted(by: \.key) {
      let normalizedWeight = Double(weight) / Double(weightsSum)
      let range = nextRangeStart..<nextRangeStart + normalizedWeight
      normalizedWeights.append((range, champion))
      nextRangeStart += normalizedWeight
    }

    var availableWeights = normalizedWeights
    var rng = LinearRandomNumberGenerator(seed: calcSeed(of: seedValue))
    for _ in 0..<count {
      var champion: String?
      // TODO Use more efficient way of not reselecting the same champion.
      while champion == nil {
        let weight = Double(rng.next() % 1000) / 1000
        let index = availableWeights.firstIndex { (range, _) in range.contains(weight) }
        if let index {
          champion = availableWeights.remove(at: index).1
        }
      }
      guard let champion, let indexToRemove = available.firstIndex(of: champion) else {
        throw .unexpected
      }
      available.remove(at: indexToRemove)
      selected.append(champion)
    }
  }

  func selectByRandom(
    from available: inout [String], into selected: inout [String],
    count: Int
  ) {
    for _ in 0..<count {
      let index = Int.random(in: 0..<available.count)
      selected.append(available.remove(at: index))
    }
  }
}

enum RotationForecastError: Error {
  case unexpected
}

struct RotationCountAllocation {
  let interval: Int
  let frequency: Int
  let random: Int
}
