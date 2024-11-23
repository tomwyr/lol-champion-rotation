import Vapor

struct RefreshVersionResult: Content {
  let versionChanged: Bool
  let latestVersion: String
}
