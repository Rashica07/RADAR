import SwiftUI

/// Album, playlist or genre: a cover header, Play / Shuffle, then the tracks.
struct TrackCollectionScreen: View {
    enum Source: Hashable { case album(String), editorial(String), user(String), genre(String) }
    let source: Source

    @Environment(PlayerStore.self) private var player
    @Environment(LibraryStore.self) private var library
    @Environment(\.dismiss) private var dismiss
    @State private var renaming = false
    @State private var newName = ""

    private struct Resolved { var title: String; var subtitle: String; var art: ArtSpec; var ids: [String] }

    private var resolved: Resolved? {
        let c = DemoCatalog.shared
        switch source {
        case .album(let id):
            guard let a = c.album(id) else { return nil }
            return Resolved(title: a.title, subtitle: "\(c.artist(a.artistId)?.name ?? "") · \(a.kind) · \(a.year)", art: c.art(for: a), ids: a.trackIds)
        case .editorial(let id):
            guard let p = c.playlist(id) else { return nil }
            return Resolved(title: p.title, subtitle: "\(p.curator) · \(p.blurb)", art: c.art(forPlaylistSeed: p.seed), ids: p.trackIds)
        case .user(let id):
            guard let p = library.playlist(id) else { return nil }
            return Resolved(title: p.title, subtitle: p.blurb, art: c.art(forPlaylistSeed: p.seed), ids: p.trackIds)
        case .genre(let id):
            guard let g = c.genres.first(where: { $0.id == id }) else { return nil }
            return Resolved(title: g.name, subtitle: g.blurb, art: c.art(for: g),
                            ids: c.tracks.filter { $0.genre == g.name }.sorted { $0.plays > $1.plays }.map(\.id))
        }
    }

    var body: some View {
        if let r = resolved {
            let tracks = r.ids.compactMap { DemoCatalog.shared.track($0) ?? nil }
            List {
                Section {
                    VStack(spacing: 14) {
                        ArtworkView(r.art).aspectRatio(1, contentMode: .fit).frame(maxWidth: 260).clipShape(.rect(cornerRadius: 12))
                        Text(r.subtitle).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        HStack(spacing: 12) {
                            Button { play(r.ids, shuffled: false) } label: { Label("Play", systemImage: "play.fill").frame(maxWidth: .infinity) }
                                .buttonStyle(.borderedProminent)
                            Button { play(r.ids, shuffled: true) } label: { Label("Shuffle", systemImage: "shuffle").frame(maxWidth: .infinity) }
                                .buttonStyle(.bordered)
                        }
                        .controlSize(.large).disabled(tracks.isEmpty)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear).listRowSeparator(.hidden)
                }
                Section {
                    if tracks.isEmpty {
                        ContentUnavailableView("No tracks yet", systemImage: "music.note", description: Text("Add tracks from any track's menu."))
                    }
                    ForEach(tracks) { t in
                        TrackRowView(track: t, context: r.ids)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if case .user(let id) = source, let i = r.ids.firstIndex(of: t.id) {
                                    Button(role: .destructive) { library.remove(at: i, from: id) } label: { Label("Remove", systemImage: "minus.circle") }
                                }
                            }
                    }
                }
            }
            .radarListBackground()
            .navigationTitle(r.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if case .user(let id) = source {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button("Rename", systemImage: "pencil") { newName = r.title; renaming = true }
                            Button("Delete playlist", systemImage: "trash", role: .destructive) { library.deletePlaylist(id); dismiss() }
                        } label: { Image(systemName: "ellipsis.circle") }
                    }
                }
            }
            .alert("Rename playlist", isPresented: $renaming) {
                TextField("Name", text: $newName)
                Button("Save") { if case .user(let id) = source { library.rename(id, to: newName) } }
                Button("Cancel", role: .cancel) {}
            }
        } else {
            ContentUnavailableView("Not found", systemImage: "questionmark.circle")
        }
    }

    private func play(_ ids: [String], shuffled: Bool) {
        guard let first = (shuffled ? ids.randomElement() : ids.first) else { return }
        if shuffled != player.shuffle { player.toggleShuffle() }
        player.play(first, in: ids)
    }
}

struct ArtistScreen: View {
    let id: String
    @Environment(PlayerStore.self) private var player

    var body: some View {
        let c = DemoCatalog.shared
        if let a = c.artist(id) {
            let tracks = c.tracks(by: id).sorted { $0.plays > $1.plays }
            let ids = tracks.map(\.id)
            List {
                Section {
                    VStack(spacing: 12) {
                        ArtworkView(c.art(for: a)).aspectRatio(1, contentMode: .fit).frame(maxWidth: 220).clipShape(.circle)
                        Text("\(Format.compact(a.listeners)) monthly listeners · \(c.countryName(a.country))").font(.subheadline).foregroundStyle(.secondary)
                        Text(a.bio).font(.callout).multilineTextAlignment(.center)
                        Button { if let f = ids.first { player.play(f, in: ids) } } label: { Label("Play", systemImage: "play.fill").frame(maxWidth: .infinity) }
                            .buttonStyle(.borderedProminent).controlSize(.large).disabled(ids.isEmpty)
                    }
                    .frame(maxWidth: .infinity).listRowBackground(Color.clear).listRowSeparator(.hidden)
                }
                Section("Popular") { ForEach(tracks.prefix(8)) { TrackRowView(track: $0, context: ids) } }
                let albums = c.albums(by: id)
                if !albums.isEmpty {
                    Section("Releases") {
                        Rail { ForEach(albums) { al in
                            NavigationLink(value: Route.album(al.id)) { CoverTile(art: c.art(for: al), title: al.title, subtitle: "\(al.kind) · \(al.year)") }.buttonStyle(.plain)
                        } }
                    }
                }
            }
            .radarListBackground()
            .navigationTitle(a.name)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("Not found", systemImage: "questionmark.circle")
        }
    }
}
