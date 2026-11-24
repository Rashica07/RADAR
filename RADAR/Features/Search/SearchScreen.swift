import SwiftUI

/// Native search: the system search field, recent searches as suggestions, grouped results.
struct SearchScreen: View {
    @Environment(LibraryStore.self) private var library
    @State private var query = ""

    var body: some View {
        let catalog = DemoCatalog.shared
        let results = catalog.search(query)
        Group {
            if query.trimmingCharacters(in: .whitespaces).isEmpty {
                List {
                    if !library.searches.isEmpty {
                        Section {
                            ForEach(library.searches, id: \.self) { q in
                                Button { query = q } label: { Label(q, systemImage: "clock.arrow.circlepath") }
                                    .swipeActions { Button(role: .destructive) { library.removeSearch(q) } label: { Label("Remove", systemImage: "trash") } }
                            }
                        } header: {
                            HStack { Text("Recent"); Spacer(); Button("Clear") { library.clearSearches() }.textCase(nil) }
                        }
                    }
                    Section("Browse genres") {
                        ForEach(catalog.genres) { g in
                            NavigationLink(value: Route.genre(g.id)) {
                                HStack(spacing: 12) {
                                    ArtworkView(catalog.art(for: g)).frame(width: 44, height: 44).clipShape(.rect(cornerRadius: 6))
                                    VStack(alignment: .leading) { Text(g.name); Text(g.blurb).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
                                }
                            }
                        }
                    }
                }
                .radarListBackground()
            } else if results.total == 0 {
                ContentUnavailableView.search(text: query)
            } else {
                List {
                    if !results.tracks.isEmpty {
                        Section("Tracks") {
                            let ids = results.tracks.map(\.id)
                            ForEach(results.tracks.prefix(12)) { TrackRowView(track: $0, context: ids) }
                        }
                    }
                    if !results.artists.isEmpty {
                        Section("Artists") {
                            ForEach(results.artists) { a in
                                NavigationLink(value: Route.artist(a.id)) {
                                    HStack(spacing: 12) {
                                        ArtworkView(catalog.art(for: a)).frame(width: 44, height: 44).clipShape(.circle)
                                        VStack(alignment: .leading) { Text(a.name); Text(a.genres.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary) }
                                    }
                                }
                            }
                        }
                    }
                    if !results.albums.isEmpty {
                        Section("Albums") {
                            ForEach(results.albums) { a in
                                NavigationLink(value: Route.album(a.id)) {
                                    HStack(spacing: 12) {
                                        ArtworkView(catalog.art(for: a)).frame(width: 44, height: 44).clipShape(.rect(cornerRadius: 6))
                                        VStack(alignment: .leading) { Text(a.title); Text(catalog.artist(a.artistId)?.name ?? "").font(.caption).foregroundStyle(.secondary) }
                                    }
                                }
                            }
                        }
                    }
                    if !results.playlists.isEmpty {
                        Section("Playlists") {
                            ForEach(results.playlists) { p in
                                NavigationLink(value: Route.playlist(p.id)) {
                                    HStack(spacing: 12) {
                                        ArtworkView(catalog.art(forPlaylistSeed: p.seed)).frame(width: 44, height: 44).clipShape(.rect(cornerRadius: 6))
                                        VStack(alignment: .leading) { Text(p.title); Text(p.curator).font(.caption).foregroundStyle(.secondary) }
                                    }
                                }
                            }
                        }
                    }
                }
                .radarListBackground()
            }
        }
        .navigationTitle("Search")
        .searchable(text: $query, prompt: "Tracks, artists, albums")
        .onSubmit(of: .search) { library.addSearch(query) }
        .radarDestinations()
    }
}
