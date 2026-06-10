import Vapor

func feedbackRoutes(_ app: Application, _ deps: Dependencies) {
  let mobileUserGuard = deps.mobileUserGuard

  app.protected(with: mobileUserGuard).grouped("feedbacks") { feedback in
    feedback.post { req in
      _ = try req.auth.require(MobileUserAuth.self)
      let input = try req.content.decode(UserFeedbackInput.self)
      let feedbackService = deps.feedbackService(request: req)
      try await feedbackService.recordUserFeedback(input)
      return HTTPStatus.noContent
    }
  }
}

extension FeedbackError: AbortError {
  var status: HTTPStatus {
    switch self {
    case .invalidInput:
      .badRequest
    case .feedbackNotCreated:
      .internalServerError
    }
  }

  var reason: String {
    switch self {
    case .invalidInput(let cause):
      "Invalid input: \(describe(cause))"
    case .feedbackNotCreated:
      "Failed to create feedback record"
    }
  }

  private func describe(_ error: UserFeedbackError) -> String {
    switch error {
    case .messageEmpty:
      "Message must not be empty"
    case .messageTooLong(let maxLength):
      "Message must not exceed \(maxLength) characters"
    }
  }
}
