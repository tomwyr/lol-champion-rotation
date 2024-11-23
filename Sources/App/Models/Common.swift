import Vapor

struct RefreshDataResult: Content {
  var version: RefreshVersionResult
  var rotation: RefreshRotationResult
}
