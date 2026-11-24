import SwiftUI

/// Compact player: cover, title, play/pause. Sits in the tab bar's bottom accessory on iOS 26
/// and above a plain tab bar before that. Tap opens the full player.
struct MiniPlayerBar: View {
    @Environment(PlayerStore.self) private var player

    var body: some View {
        if let track = player.current {
            let catalog = DemoCatalog.shared
            HStack(spacing: 12) {
                Button { player.expanded = true } label: {
                    HStack(spacing: 12) {
                        ArtworkView(catalog.art(for: track)).frame(width: 36, height: 36).clipShape(.rect(cornerRadius: 5))
                        VStack(alignment: .leading, spacing: 0) {
                            Text(track.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                            Text(player.isDemoPlayback ? "Demo playback" : catalog.artistName(for: track))
                                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open player, \(track.title)")
                Button { player.toggle() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill").font(.title3).frame(width: 40, height: 40)
                }
                .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
                Button { player.next() } label: {
                    Image(systemName: "forward.fill").font(.body).frame(width: 40, height: 40)
                }
                .accessibilityLabel("Next track")
            }
            .padding(.horizontal, 12)
            .tint(.primary)
        }
    }
}

/// Full player, presented as a native sheet.
struct NowPlayingSheet: View {
    @Environment(PlayerStore.self) private var player
    @Environment(\.dismiss) private var dismiss
    @State private var page = Page.now

    enum Page: String, CaseIterable, Identifiable {
        case now = "Now playing", queue = "Queue"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Page", selection: $page) {
                    ForEach(Page.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented).padding(.horizontal).padding(.bottom, 8)
                switch page {
                case .now: NowPlayingPage()
                case .queue: QueuePage()
                }
            }
            .background(Color.radarBg)
            .navigationTitle(player.isDemoPlayback ? "Demo playback" : "Now playing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "chevron.down") { dismiss() }
                }
            }
        }
        .tint(Color.radarAccentText)
        .presentationDragIndicator(.visible)
    }
}

private struct NowPlayingPage: View {
    @Environment(PlayerStore.self) private var player
    @Environment(LibraryStore.self) private var library
    @State private var scrubbing: Double?

    var body: some View {
        if let track = player.current {
            let catalog = DemoCatalog.shared
            ScrollView {
                VStack(spacing: 20) {
                    ArtworkView(catalog.art(for: track))
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(.rect(cornerRadius: 14))
                        .shadow(radius: 18, y: 8)
                        .frame(maxWidth: 440)
                        .accessibilityHidden(true)
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.title).font(.title2.bold()).lineLimit(2)
                            Text(catalog.artistName(for: track)).font(.title3).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            _ = library.toggleSave(track.id)
                        } label: {
                            Image(systemName: library.isSaved(track.id) ? "heart.fill" : "heart").font(.title2)
                                .foregroundStyle(library.isSaved(track.id) ? Color.radarSignalText : .primary)
                        }
                        .sensoryFeedback(.success, trigger: library.isSaved(track.id)) { _, new in new }
                        .accessibilityLabel(library.isSaved(track.id) ? "Remove from Saved" : "Save")
                        Menu { TrackMenu(track: track) } label: { Image(systemName: "ellipsis.circle").font(.title2) }
                    }
                    if let error = player.playbackError {
                        Label(error, systemImage: "exclamationmark.triangle").font(.footnote).foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    VStack(spacing: 4) {
                        Slider(value: Binding(get: { scrubbing ?? player.fraction }, set: { scrubbing = $0 }), in: 0...1) { editing in
                            if !editing, let f = scrubbing { player.seek(fraction: f); scrubbing = nil }
                        }
                        .accessibilityLabel("Playback position")
                        .accessibilityValue("\(Format.time(player.progress)) of \(Format.time(player.duration))")
                        HStack {
                            Text(Format.time((scrubbing ?? player.fraction) * player.duration))
                            Spacer()
                            Text("-" + Format.time(player.duration - (scrubbing ?? player.fraction) * player.duration))
                        }
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    HStack {
                        Toggle(isOn: Binding(get: { player.shuffle }, set: { _ in player.toggleShuffle() })) {
                            Image(systemName: "shuffle")
                        }.toggleStyle(.button).accessibilityLabel("Shuffle")
                        Spacer()
                        Button { player.previous() } label: { Image(systemName: "backward.fill").font(.title) }
                            .accessibilityLabel("Previous track")
                        Spacer()
                        Button { player.toggle() } label: {
                            Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill").font(.system(size: 64))
                        }
                        .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
                        Spacer()
                        Button { player.next() } label: { Image(systemName: "forward.fill").font(.title) }
                            .accessibilityLabel("Next track")
                        Spacer()
                        Button { player.cycleRepeat() } label: {
                            Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat")
                                .foregroundStyle(player.repeatMode == .off ? Color.secondary : Color.radarAccentText)
                        }
                        .accessibilityLabel("Repeat \(player.repeatMode.rawValue)")
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: player.repeatMode)
                    HStack {
                        Image(systemName: "speaker.fill").foregroundStyle(.secondary)
                        Slider(value: Binding(get: { player.volume }, set: { player.setVolume($0) }), in: 0...1)
                            .accessibilityLabel("Volume")
                        Image(systemName: "speaker.wave.3.fill").foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        } else {
            ContentUnavailableView("Nothing playing", systemImage: "play.circle", description: Text("Pick a track to start."))
        }
    }
}

private struct QueuePage: View {
    @Environment(PlayerStore.self) private var player

    var body: some View {
        let catalog = DemoCatalog.shared
        let tracks = player.queueTracks
        if tracks.isEmpty {
            ContentUnavailableView("Queue is empty", systemImage: "list.bullet", description: Text("Play something and it lines up here."))
        } else {
            List {
                Section("\(tracks.count) in queue") {
                    ForEach(Array(tracks.enumerated()), id: \.offset) { i, t in
                        let current = i == player.queue.index
                        Button { player.jump(to: i) } label: {
                            HStack(spacing: 12) {
                                ArtworkView(catalog.art(for: t)).frame(width: 44, height: 44).clipShape(.rect(cornerRadius: 6))
                                VStack(alignment: .leading) {
                                    Text(t.title).foregroundStyle(current ? Color.radarAccentText : .primary).lineLimit(1)
                                    Text(catalog.artistName(for: t)).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                                }
                                Spacer()
                                if current { Image(systemName: "speaker.wave.2.fill").foregroundStyle(Color.radarAccentText) }
                            }
                        }
                        .buttonStyle(.plain)
                        .swipeActions { Button(role: .destructive) { player.removeAt(i) } label: { Label("Remove", systemImage: "trash") } }
                    }
                }
                if !player.upcomingTracks.isEmpty {
                    Section { Button("Clear upcoming", role: .destructive) { withAnimation { player.clearUpcoming() } } }
                }
            }
            .radarListBackground()
        }
    }
}
