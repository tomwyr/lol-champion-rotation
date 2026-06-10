import Testing

@testable import App

extension AppTests {
  @Suite(.serialized) struct CreateFeedbackTests {
    @Test func missingAuth() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(),
          body: ["message": "content"],
        ) { res async throws in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test func webAuth() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: webApiKey),
          body: ["message": "content"],
        ) { res async throws in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test func mobileAuth() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileAccessToken),
          body: ["message": "content"],
        ) { res async throws in
          #expect(res.status == .noContent)
        }
      }
    }

    @Test func feedbackWithValidData() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileAccessToken),
          body: ["message": "content"],
        ) { res async throws in
          #expect(res.status == .noContent)
        }
      }
    }

    @Test func feedbackWithoutMessage() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileAccessToken),
          body: ["type": "bug"],
        ) { res async throws in
          #expect(res.status == .badRequest)
        }
      }
    }

    @Test func feedbackWithEmptyMessage() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileAccessToken),
          body: ["message": ""],
        ) { res async throws in
          #expect(res.status == .badRequest)
          try expectBodyError(res.body, "Invalid input: Message must not be empty")
        }
      }
    }

    @Test func feedbackWithTooLongMessage() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        let maxLength = UserFeedback.messageMaxLength
        let message = String(repeating: "a", count: maxLength + 1)

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileAccessToken),
          body: ["message": message],
        ) { res async throws in
          #expect(res.status == .badRequest)
          try expectBodyError(
            res.body,
            "Invalid input: Message must not exceed \(maxLength) characters",
          )
        }
      }
    }

    @Test func linearIssueCreation() async throws {
      try await withApp { app in
        let issueData = CreateIssueData(issueCreate: CreateIssueResult(success: true))

        let mocks = try await app.testConfigureWith(
          linearAccessToken: "123",
          linearTeamId: "456",
          linearFeedbackStateId: "789",
          linearCreateIssueData: issueData,
        )

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileAccessToken),
          body: ["message": "content"],
        ) { res async throws in
          #expect(res.status == .noContent)
          #expect(mocks.graphQLClient.requestedQueries == [LinearClient.createIssueMutation])
          let expectedVariables = [
            "teamId": "456",
            "stateId": "789",
            "title": "[Other] User feedback",
            "description": "content",
          ]
          #expect(mocks.graphQLClient.requestedVariables == [expectedVariables])
          let expectedHeaders = ["Authorization": "123"]
          #expect(mocks.graphQLClient.requestedHeaders == [expectedHeaders])
        }
      }
    }

    @Test func linearIssueCreationWithBugType() async throws {
      try await withApp { app in
        let issueData = CreateIssueData(issueCreate: CreateIssueResult(success: true))

        let mocks = try await app.testConfigureWith(
          linearAccessToken: "123",
          linearTeamId: "456",
          linearFeedbackStateId: "789",
          linearCreateIssueData: issueData,
        )

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileAccessToken),
          body: ["message": "content", "type": "bug"],
        ) { res async throws in
          #expect(res.status == .noContent)
          #expect(mocks.graphQLClient.requestedQueries == [LinearClient.createIssueMutation])
          let expectedVariables = [
            "teamId": "456",
            "stateId": "789",
            "title": "[Bug] User feedback",
            "description": "content",
          ]
          #expect(mocks.graphQLClient.requestedVariables == [expectedVariables])
        }
      }
    }

    @Test func linearIssueCreationWithFeatureType() async throws {
      try await withApp { app in
        let issueData = CreateIssueData(issueCreate: CreateIssueResult(success: true))

        let mocks = try await app.testConfigureWith(
          linearAccessToken: "123",
          linearTeamId: "456",
          linearFeedbackStateId: "789",
          linearCreateIssueData: issueData,
        )

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileAccessToken),
          body: ["message": "content", "type": "feature"],
        ) { res async throws in
          #expect(res.status == .noContent)
          #expect(mocks.graphQLClient.requestedQueries == [LinearClient.createIssueMutation])
          let expectedVariables = [
            "teamId": "456",
            "stateId": "789",
            "title": "[Feature] User feedback",
            "description": "content",
          ]
          #expect(mocks.graphQLClient.requestedVariables == [expectedVariables])
        }
      }
    }

    @Test func linearIssueCreationWithUnknownType() async throws {
      try await withApp { app in
        let issueData = CreateIssueData(issueCreate: CreateIssueResult(success: true))

        let mocks = try await app.testConfigureWith(
          linearAccessToken: "123",
          linearTeamId: "456",
          linearFeedbackStateId: "789",
          linearCreateIssueData: issueData,
        )

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileAccessToken),
          body: ["message": "content", "type": "other"],
        ) { res async throws in
          #expect(res.status == .badRequest)
          #expect(mocks.graphQLClient.requestedVariables.isEmpty)

        }
      }
    }

    @Test func linearIssueCreationUnsuccessful() async throws {
      try await withApp { app in
        let issueData = CreateIssueData(issueCreate: CreateIssueResult(success: false))

        _ = try await app.testConfigureWith(
          linearAccessToken: "123",
          linearTeamId: "456",
          linearFeedbackStateId: "789",
          linearCreateIssueData: issueData,
        )

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileAccessToken),
          body: ["message": "content"],
        ) { res async throws in
          #expect(res.status == .internalServerError)
          try expectBodyError(res.body, "Failed to create feedback record")
        }
      }
    }
  }
}
