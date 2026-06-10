import Vapor

struct UserFeedbackInput: Content {
  let message: String
  let type: UserFeedbackType?
}

enum UserFeedbackType: String, Content {
  case bug, feature
}

struct UserFeedback {
  let message: String
  let type: UserFeedbackType?

  static let messageMaxLength = 1000

  init(input: UserFeedbackInput) throws(UserFeedbackError) {
    let message = input.message.trimmingCharacters(in: .whitespaces)
    guard !message.isEmpty else { throw .messageEmpty }
    guard message.count < Self.messageMaxLength else {
      throw .messageTooLong(maxLength: Self.messageMaxLength)
    }
    self.message = message

    self.type = input.type
  }
}

enum UserFeedbackError: Error {
  case messageEmpty
  case messageTooLong(maxLength: Int)
}
