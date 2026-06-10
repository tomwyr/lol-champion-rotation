struct FeedbackService {
  let linearClient: LinearClient
  let linearTeamId: String
  let linearFeedbackStateId: String

  func recordUserFeedback(_ input: UserFeedbackInput) async throws {
    let userFeedback = try validateInput(input)

    let payload = try await linearClient.createIssue(
      teamId: linearTeamId,
      stateId: linearFeedbackStateId,
      title: buildTitle(userFeedback),
      description: userFeedback.message,
    )

    if !payload.success {
      throw FeedbackError.feedbackNotCreated
    }
  }

  private func validateInput(_ input: UserFeedbackInput) throws -> UserFeedback {
    do {
      return try UserFeedback(input: input)
    } catch {
      throw FeedbackError.invalidInput(cause: error)
    }
  }

  private func buildTitle(_ userFeedback: UserFeedback) -> String {
    let typeName =
      switch userFeedback.type {
      case .bug: "[Bug]"
      case .feature: "[Feature]"
      case nil: "[Other]"
      }

    return "\(typeName) User feedback"
  }
}

enum FeedbackError: Error {
  case invalidInput(cause: UserFeedbackError)
  case feedbackNotCreated
}
