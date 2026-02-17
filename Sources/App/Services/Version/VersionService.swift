import Foundation

protocol VersionService {
  func latestVersion() async throws -> String
  func findVersion(olderThan: Date) async throws -> String
  func refreshVersion() async throws -> RefreshVersionResult
}

struct DefaultVersionService<Version: RiotPatchVersion>: VersionService {
  let versionType: Version.Type
  let riotApiClient: RiotApiClient
  let appDb: AppDatabase

  func latestVersion() async throws -> String {
    let data = try await getLocalVersion(using: appDb.latestPatchVersion)
    guard let version = data?.rawValue else {
      throw PatchVersionError.latestVersionUnknown
    }
    return version
  }

  func findVersion(olderThan: Date) async throws -> String {
    let data = try await getLocalVersion {
      try await appDb.patchVersion(olderThan: olderThan)
    }
    guard let data else {
      throw PatchVersionError.latestVersionUnknown
    }
    return data.rawValue
  }

  func refreshVersion() async throws -> RefreshVersionResult {
    let localVersion = try await getLocalVersion(using: appDb.latestPatchVersion)
    let riotVersion = try await getLatestRiotVersion()

    let (versionChanged, latestVersion) = resolveVersion(localVersion, riotVersion)
    if versionChanged {
      try await saveLatestLocalVersion(latestVersion)
    }

    return RefreshVersionResult(
      versionChanged: versionChanged,
      latestVersion: latestVersion.rawValue
    )
  }

  private func getLatestRiotVersion() async throws -> Version {
    let allVersions = try await riotApiClient.patchVersions()
    guard let latestVersion = Version.newestOf(versions: allVersions) else {
      throw PatchVersionError.noValidRiotVersion(allVersions: allVersions)
    }
    return latestVersion
  }

  private func getLocalVersion(
    using queryModel: () async throws -> PatchVersionModel?,
  ) async throws -> Version? {
    guard let value = try await queryModel()?.value else {
      return nil
    }
    guard let latestVersion = try? Version(rawValue: value) else {
      throw PatchVersionError.localVersionInvalid(value: value)
    }
    return latestVersion
  }

  private func saveLatestLocalVersion(_ version: Version) async throws {
    let data = PatchVersionModel(value: version.rawValue)
    try await appDb.savePatchVersion(data: data)
  }

  private func resolveVersion(
    _ localVersion: Version?, _ riotVersion: Version,
  ) -> ResolveVersionResult<Version> {
    guard let localVersion else {
      return (versionChanged: true, latestVersion: riotVersion)
    }
    return if Version.increased(from: localVersion, to: riotVersion) {
      (versionChanged: true, latestVersion: riotVersion)
    } else {
      (versionChanged: false, latestVersion: localVersion)
    }
  }
}

private typealias ResolveVersionResult<Version: RiotPatchVersion> = (
  versionChanged: Bool, latestVersion: Version
)

enum PatchVersionError: Error {
  case latestVersionUnknown
  case versionNotFound(olderThan: Date)
  case localVersionInvalid(value: String?)
  case noValidRiotVersion(allVersions: [String])
}
