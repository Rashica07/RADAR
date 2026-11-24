import SwiftUI
import UniformTypeIdentifiers

/// Saved, playlists, recent, downloads and imported files, under a system segmented picker.
struct LibraryScreen: View {
    enum Section: String, CaseIterable, Identifiable {
        case saved = "Saved", playlists = "Playlists", recent = "Recent", offline = "Offline", local = "Files"
        var id: String { rawValue }
    }

    @Environment(LibraryStore.self) private var library
    @Environment(LocalLibrary.self) private var local
    @Environment(DownloadCenter.self) private var downloads
    @Environment(PlayerStore.self) private var player
    @Environment(ToastCenter.self) private var toasts
    @State private var section = Section.saved
    @State private var showImporter = false
    @State private var showSettings = false

    var body: some View {
        let catalog = DemoCatalog.shared
        List {
            SwiftUI.Section {
                Picker("Section", selection: $section) { ForEach(Section.allCases) { Text($0.rawValue).tag($0) } }
                    .pickerStyle(.segmented).listRowBackground(Color.clear)
            }
            switch section {
            case .saved:
                let ids = library.saved
                rows(ids, empty: ("No saved tracks", "heart", "Tap the heart on any track."))
            case .recent:
                let ids = library.recent.map(\.id)
                rows(ids, empty: ("Nothing played yet", "clock", "What you play shows up here."))
            case .offline:
                let tracks = downloads.offlineTracks
                SwiftUI.Section { Text("Simulated: demo tracks aren't real audio files.").font(.footnote).foregroundStyle(.secondary) }
                    .listRowBackground(Color.clear)
                if tracks.isEmpty {
                    ContentUnavailableView("No downloads", systemImage: "arrow.down.circle", description: Text("Download a track from its menu."))
                        .listRowBackground(Color.clear)
                }
                ForEach(tracks) { t in
                    TrackRowView(track: t, context: tracks.map(\.id))
                        .swipeActions { Button(role: .destructive) { downloads.remove(t.id) } label: { Label("Remove", systemImage: "trash") } }
                }
            case .local:
                if local.tracks.isEmpty {
                    ContentUnavailableView {
                        Label("No files yet", systemImage: "folder")
                    } description: {
                        Text("Import audio from Files. It stays on this device.")
                    } actions: {
                        Button("Import audio") { showImporter = true }.buttonStyle(.borderedProminent)
                    }
                    .listRowBackground(Color.clear)
                }
                ForEach(local.tracks) { t in
                    TrackRowView(track: t, context: local.tracks.map(\.id))
                        .swipeActions {
                            Button(role: .destructive) {
                                player.purge(trackId: t.id); library.purge(trackId: t.id); local.delete(t.id)
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                }
            case .playlists:
                if library.playlists.isEmpty {
                    ContentUnavailableView("No playlists", systemImage: "music.note.list", description: Text("Create one with the + button."))
                        .listRowBackground(Color.clear)
                }
                ForEach(library.playlists) { p in
                    NavigationLink(value: Route.userPlaylist(p.id)) {
                        HStack(spacing: 12) {
                            ArtworkView(catalog.art(forPlaylistSeed: p.seed)).frame(width: 48, height: 48).clipShape(.rect(cornerRadius: 6))
                            VStack(alignment: .leading) { Text(p.title); Text(Format.plural(p.trackIds.count, "track")).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                    .swipeActions { Button(role: .destructive) { library.deletePlaylist(p.id) } label: { Label("Delete", systemImage: "trash") } }
                }
            }
        }
        .radarListBackground()
        .navigationTitle("Library")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                switch section {
                case .playlists: Button("New playlist", systemImage: "plus") { _ = library.createPlaylist() }
                case .local: Button("Import", systemImage: "square.and.arrow.down") { showImporter = true }
                default: EmptyView()
                }
            }
            SettingsButton(show: $showSettings)
        }
        .settingsSheet($showSettings)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: LocalLibrary.supportedTypes, allowsMultipleSelection: true) { result in
            guard case .success(let urls) = result else { return }
            Task {
                let r = await local.importFiles(urls)
                toasts.show(r.failed == 0 ? "Imported \(Format.plural(r.imported, "file"))" : "\(r.imported) imported, \(r.failed) failed",
                            symbol: r.failed == 0 ? "checkmark" : "exclamationmark.triangle")
            }
        }
        .radarDestinations()
    }

    @ViewBuilder
    private func rows(_ ids: [String], empty: (String, String, String)) -> some View {
        let tracks = ids.compactMap { DemoCatalog.shared.track($0) ?? local.track($0) }
        if tracks.isEmpty {
            ContentUnavailableView(empty.0, systemImage: empty.1, description: Text(empty.2)).listRowBackground(Color.clear)
        }
        ForEach(tracks) { TrackRowView(track: $0, context: tracks.map(\.id)) }
    }
}
