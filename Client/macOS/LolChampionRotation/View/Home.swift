import Foundation
import SwiftUI

struct HomePage: View {
    @StateObject var store = RotationStore(
        repository: RotationRepository(
            sessionKey: UUID().uuidString,
            httpClient: NetworkHttpClient()
        )
    )

    var body: some View {
        currentStateView
            .onAppear { store.loadCurrentRotation() }
    }

    @ViewBuilder
    var currentStateView: some View {
        switch store.state {
        case .initial, .loading:
            loadingView
        case .error:
            errorView
        case let .data(rotation):
            RotationView(rotation: rotation)
        }
    }

    var loadingView: some View {
        VStack {
            ProgressView()
            Text("Loading...").padding(.top, 4).font(.title3)
        }
    }

    var errorView: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle").font(.system(size: 48))
            Text("Failed to load data. Please try again.").font(.title3).padding(.top, 8)
            Button(action: store.loadCurrentRotation) {
                Text("Refresh")
            }.padding(.top, 12)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomePage()
    }
}
