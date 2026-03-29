import Testing
import Vapor

@testable import App

extension Dependencies {
  static func mock(
    appConfig: AppConfig = .empty(),
    httpClient: HttpClient = MockHttpClient(),
    graphQLClient: GraphQLClient = MockGraphQLClient(),
    fcm: FcmDispatcher = MockFcmDispatcher(),
    rotationForecast: RotationForecast = SpyRotationForecast(),
    instant: Instant = MockInstant(),
  ) -> Dependencies {
    .init(
      appConfig: appConfig,
      httpClient: httpClient,
      graphQLClient: graphQLClient,
      fcm: { _ in fcm },
      rotationForecast: rotationForecast,
      instant: instant,
    )
  }
}
