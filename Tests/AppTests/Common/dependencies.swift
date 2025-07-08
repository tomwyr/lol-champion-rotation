import Testing
import Vapor

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
      fcm: { _ in fcm },
      mobileUserGuard: mobileUserGuard,
      optionalMobileUserGuard: optionalMobileUserGuard
    )
  }
}
