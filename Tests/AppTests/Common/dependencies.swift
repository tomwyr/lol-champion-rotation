import Vapor
import XCTest

@testable import App

extension Dependencies {
  static func mock(
    appConfig: AppConfig = .empty(),
    httpClient: HttpClient = MockHttpClient(),
    fcm: FcmDispatcher = MockFcmDispatcher(),
    mobileUserGuard: RequestAuthenticatorGuard = MockMobileUserGuard(),
    optionalMobileUserGuard: RequestAuthenticatorGuard = MockOptionalMobileUserGuard()
  ) -> Dependencies {
    .init(
      appConfig: appConfig,
      httpClient: httpClient,
      fcm: fcm,
      mobileUserGuard: mobileUserGuard,
      optionalMobileUserGuard: optionalMobileUserGuard
    )
  }
}
