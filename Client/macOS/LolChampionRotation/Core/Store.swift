import SwiftUI

@MainActor
class RotationStore: ObservableObject {
    private let repository: RotationRepository

    init(repository: RotationRepository) {
        self.repository = repository
    }

    @Published var state: CurrentRotationState = .initial

    func loadCurrentRotation() {
        let repository = self.repository

        Task {
            if case .loading = state { return }

            state = .loading
            do {
                let currentRotation = try await repository.currentRotation()
                state = .data(currentRotation)
            } catch let error as CurrentRotationError {
                state = .error(error)
            }
        }
    }
}

enum CurrentRotationState {
    case initial
    case loading
    case data(ChampionRotation)
    case error(CurrentRotationError)
}
