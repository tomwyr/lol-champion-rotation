import Vapor

struct UserFeedbackInput: Content {
  let title: String?
  let description: String
  let type: UserFeedbackType?
}

enum UserFeedbackType: String, Content {
  case bug, feature
}

struct UserFeedback {
  let title: String?
  let description: String
  let type: UserFeedbackType?

  static let titleMaxLength = 50
  static let descriptionMaxLength = 1000

  init(input: UserFeedbackInput) throws(UserFeedbackError) {
    if var title = input.title {
      title = title.trimmingCharacters(in: .whitespaces)
      guard !title.isEmpty else { throw .titleEmpty }
      guard title.count < Self.titleMaxLength else {
        throw .titleTooLong(maxLength: Self.titleMaxLength)
      }
      self.title = title
    } else {
      self.title = nil
    }

    let description = input.description.trimmingCharacters(in: .whitespaces)
    guard !description.isEmpty else { throw .descriptionEmpty }
    guard description.count < Self.descriptionMaxLength else {
      throw .descriptionTooLong(maxLength: Self.descriptionMaxLength)
    }
    self.description = description

    self.type = input.type
  }
}

enum UserFeedbackError: Error {
  case titleEmpty
  case titleTooLong(maxLength: Int)
  case descriptionEmpty
  case descriptionTooLong(maxLength: Int)
}
