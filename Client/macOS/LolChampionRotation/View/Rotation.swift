import SwiftUI

struct RotationView: View {
    let rotation: ChampionRotation

    @State var searchQuery = ""

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Current champion rotation").font(.title)
                        Spacer()
                        SearchField(query: $searchQuery)
                    }
                    Spacer().frame(height: 12)
                    ChampionsSection(
                        title: "Champions available for free",
                        subtitle: nil,
                        champions: rotation.regularChampions,
                        searchQuery: searchQuery,
                        geometry: geometry
                    )
                    Spacer().frame(height: 24)
                    ChampionsSection(
                        title: "Champions available for free for new players",
                        subtitle:
                            "New players up to level \(rotation.beginnerMaxLevel) get access to a different pool of champions",
                        champions: rotation.beginnerChampions,
                        searchQuery: searchQuery,
                        geometry: geometry
                    )
                }.padding()
            }
        }
    }
}

struct ChampionsSection: View {
    let title: String
    let subtitle: String?
    let champions: [Champion]
    let searchQuery: String
    let geometry: GeometryProxy

    var body: some View {
        let filteredChampions = filterChampions()

        return Group {
            Text(title).font(.headline)
            if let subtitle {
                Text(subtitle).font(.subheadline).foregroundColor(.gray)
            }
            Spacer().frame(height: 12)
            if filteredChampions.isEmpty {
                Text("No champions match your search query.").font(.body).foregroundColor(.gray)
            } else {
                championsGrid(filteredChampions)
            }
        }
    }

    func filterChampions() -> [Champion] {
        let formattedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return if formattedQuery.isEmpty {
            champions
        } else {
            champions.filter { $0.name.lowercased().contains(formattedQuery) }
        }
    }

    @ViewBuilder
    func championsGrid(_ champions: [Champion]) -> some View {
        let itemSize = 128.0
        let spacing = 24.0

        let rawCount = (geometry.size.width - spacing) / (itemSize + spacing)
        let count = Int(rawCount).clamp(to: 2...6)

        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: count),
            spacing: spacing
        ) {
            ForEach(champions, id: \.id) { champion in
                VStack {
                    AsyncImage(
                        url: URL(string: champion.imageUrl),
                        content: { image in image.resizable() },
                        placeholder: { ProgressView() }
                    )
                    .frame(width: itemSize, height: itemSize)
                    .cornerRadius(4)
                    Text(champion.name).font(.body).padding(.vertical, 2)
                }
            }
        }
    }
}

struct SearchField: View {
    @State var expanded: Bool = false
    @State var showBadge: Bool = false
    @Binding var query: String

    var body: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.1)) {
                    expanded.toggle()
                }
                withAnimation(.easeInOut(duration: 0.2)) {
                    showBadge = !expanded && !query.isEmpty
                }
            }) {
                Image(systemName: "magnifyingglass")
            }.overlay(alignment: .topTrailing) {
                if showBadge {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.red)
                        .allowsHitTesting(false)
                        .offset(x: 4, y: -4)
                        .transition(.scale)
                }
            }
            if expanded {
                TextField("Champion name...", text: $query)
                    .frame(maxWidth: 280)
                    .transition(
                        .asymmetric(
                            insertion: .push(from: .trailing),
                            removal: .push(from: .leading)
                        ))
            }
        }
    }
}

extension Int {
    func clamp(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
