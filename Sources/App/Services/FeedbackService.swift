struct FeedbackService {
  let linearClient: LinearClient
  let linearTeamId: String
  let linearFeedbackStateId: String

  func recordUserFeedback(_ input: UserFeedbackInput) async throws {
    let userFeedback = try validateInput(input)

    let payload = try await linearClient.createIssue(
      teamId: linearTeamId,
      stateId: linearFeedbackStateId,
      title: userFeedback.title,
      description: userFeedback.description,
    )

    if !payload.success {
      throw FeedbackError.feedbackNotCreated
    }
  }

  func validateInput(_ input: UserFeedbackInput) throws -> UserFeedback {
    do {
      return try UserFeedback(input: input)
    } catch {
      throw FeedbackError.invalidInput(cause: error)
    }
  }
}

enum FeedbackError: Error {
  case invalidInput(cause: UserFeedbackError)
  case feedbackNotCreated
}
