import Foundation

struct SlugGenerator {

  func resolveAll(rotationStarts: [Date], versions: [PatchVersionModel])
    throws(SlugGeneratorError) -> [String]
  {
    var slugs = [String]()
    for rotationStart in rotationStarts {
      let slug = try resolve(rotationStart: rotationStart, versions: versions)
      slugs.append(slug)
    }
    return slugs
  }

  func resolve(rotationStart: Date, versions: [PatchVersionModel])
    throws(SlugGeneratorError) -> String
  {
    let (startVersion, endVersion) = try resolveSeasonVersions(
      for: rotationStart, versions: versions)
    let (seasonStart, seasonEnd) = try validateSeasonDates(
      startVersion: startVersion, endVersion: endVersion)

    let season = try patchSeason(of: startVersion)
    let week = try calculateWeek(
      for: rotationStart,
      seasonStart: seasonStart, seasonEnd: seasonEnd,
    )

    return "s\(season)w\(week)"
  }

  private func resolveSeasonVersions(
    for rotationStart: Date,
    versions: [PatchVersionModel],
  ) throws(SlugGeneratorError) -> (start: PatchVersionModel, end: PatchVersionModel?) {
    var versionsUntilRotation = [PatchVersionModel]()
    for version in versions {
      guard let observedAt = version.observedAt else {
        throw .missingVersionDate(version: version.value)
      }
      guard observedAt <= rotationStart else {
        break
      }
      versionsUntilRotation.append(version)
    }

    guard let versionBeforeRotation = versionsUntilRotation.last else {
      throw .unknownSeasonStart(rotationStart: rotationStart)
    }
    let rotationSeason = try patchSeason(of: versionBeforeRotation)

    var start = versionBeforeRotation
    for version in versionsUntilRotation.reversed() {
      let season = try patchSeason(of: version)
      if season == rotationSeason {
        start = version
      } else {
        break
      }
    }

    let startIndex = versions.firstIndex { version in start === version } ?? 0
    let startSeason = try patchSeason(of: start)
    var end: PatchVersionModel?
    for version in versions[startIndex...] {
      if try patchSeason(of: version) != startSeason {
        end = version
        break
      }
    }

    return (start: start, end: end)
  }

  private func validateSeasonDates(
    startVersion: PatchVersionModel,
    endVersion: PatchVersionModel?,
  ) throws(SlugGeneratorError) -> (seasonStart: Date, seasonEnd: Date?) {
    guard let seasonStart = startVersion.observedAt else {
      throw .missingVersionDate(version: startVersion.value)
    }
    guard endVersion == nil || endVersion!.observedAt != nil else {
      throw .missingVersionDate(version: endVersion?.value)
    }
    let seasonEnd = endVersion?.observedAt
    return (seasonStart, seasonEnd)
  }

  private func calculateWeek(
    for rotationStart: Date,
    seasonStart: Date, seasonEnd: Date?,
  ) throws(SlugGeneratorError) -> Int {
    let seasonRange: any RangeExpression<Date> =
      if let seasonEnd { seasonStart..<seasonEnd } else { seasonStart... }

    guard seasonRange.contains(rotationStart) else {
      throw .invalidRotationSeason(
        rotationStart: rotationStart,
        seasonStart: seasonStart,
        seasonEnd: seasonEnd,
      )
    }

    guard let weekDiff = seasonStart.distance(to: rotationStart, in: .weekOfYear) else {
      throw .invalidWeekDiff(seasonStart: seasonStart, rotationStart: rotationStart)
    }
    return weekDiff + 1
  }

  private func patchSeason(of model: PatchVersionModel) throws(SlugGeneratorError) -> String {
    guard let season = model.value?.split(separator: ".").first else {
      throw .invalidPatchSeason(version: model.value)
    }
    return season
  }
}

extension SlugGenerator {
  func resolveAllUnique(
    rotationStarts: [Date], versions: [PatchVersionModel],
    existingSlugs: [String],
  ) throws(SlugGeneratorError) -> [String] {
    var updatedExistingSlugs = Array(existingSlugs)
    var slugs = [String]()
    for rotationStart in rotationStarts {
      let slug = try resolve(rotationStart: rotationStart, versions: versions)
      let uniqueSlug = makeSlugUnique(slug, updatedExistingSlugs)
      updatedExistingSlugs.append(uniqueSlug)
      slugs.append(uniqueSlug)
    }
    return slugs
  }

  func resolveUnique(
    rotationStart: Date, versions: [PatchVersionModel],
    existingSlugs: [String],
  ) throws(SlugGeneratorError) -> String {
    let slug = try resolve(rotationStart: rotationStart, versions: versions)
    return makeSlugUnique(slug, existingSlugs)
  }

  private func makeSlugUnique(_ slug: String, _ existingSlugs: [String]) -> String {
    var count = 0
    var uniqueSlug = ""
    repeat {
      count += 1
      uniqueSlug = if count == 1 { slug } else { "\(slug)-\(count)" }
    } while existingSlugs.contains(uniqueSlug)
    return uniqueSlug
  }
}

enum SlugGeneratorError: Error {
  case invalidPatchSeason(version: String?)
  case missingVersionDate(version: String?)
  case unknownSeasonStart(rotationStart: Date)
  case invalidRotationSeason(rotationStart: Date, seasonStart: Date, seasonEnd: Date?)
  case invalidWeekDiff(seasonStart: Date, rotationStart: Date)
}
