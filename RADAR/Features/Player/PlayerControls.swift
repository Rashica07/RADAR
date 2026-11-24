import SwiftUI

/// Shuffle · previous · play/pause · next · repeat. Shared by the expanded player and the transport bar.
struct TransportControls: View {
    @Environment(PlayerStore.self) private var player
    var big = true

    var body: some View {
        HStack(spacing: 0) {
            control(.shuffle, "Shuffle", on: player.shuffle) { player.toggleShuffle() }
            control(.prev, "Previous track") { player.previous() }
            Button { player.toggle() } label: {
                RadarIcon(player.isPlaying ? .pause : .play, size: big ? 30 : 24)
                    .foregroundStyle(Color.radarOnAccent)
                    .frame(width: big ? 68 : 48, height: big ? 68 : 48)
                    .background(Circle().fill(Color.radarAccent))
            }
            .buttonStyle(NavPressStyle())
            .frame(maxWidth: .infinity)
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
            control(.next, "Next track") { player.next() }
            control(player.repeatMode == .one ? .repeatOne : .repeat, "Repeat \(player.repeatMode.rawValue)",
                    on: player.repeatMode != .off) { player.cycleRepeat() }
        }
        .sensoryFeedback(.selection, trigger: player.repeatMode) { _, _ in Haptics.isEnabled }
        .sensoryFeedback(.selection, trigger: player.shuffle) { _, _ in Haptics.isEnabled }
    }

    private func control(_ icon: RadarIconName, _ label: String, on: Bool = false, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            RadarIcon(icon, size: 24)
                .foregroundStyle(on ? Color.radarAccentText : Color.radarText)
                .frame(maxWidth: .infinity, minHeight: RadarScale.touch + 8)
        }
        .buttonStyle(NavPressStyle())
        .accessibilityLabel(label)
        .accessibilityAddTraits(on ? [.isSelected] : [])
    }
}

/// Upcoming tracks. Tap to jump, swipe to remove; "Clear" empties what is after the current one.
struct QueueList: View {
    @Environment(PlayerStore.self) private var player
    @Environment(LibraryStore.self) private var library

    var body: some View {
        let catalog = DemoCatalog.shared
        let tracks = player.queueTracks
        if tracks.isEmpty {
            Text("Nothing queued. Play something and it will line up here.")
                .font(RadarFont.body(14, .regular, relativeTo: .body)).foregroundStyle(Color.radarText2)
                .multilineTextAlignment(.center).padding(32).frame(maxWidth: .infinity)
        } else {
            List {
                HStack {
                    Text("\(tracks.count) in queue").radarReadout()
                    Spacer()
                    if !player.upcomingTracks.isEmpty {
                        Button("Clear upcoming") { withAnimation { player.clearUpcoming() } }.buttonStyle(.radarTag(ghost: true))
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: RadarScale.gutter, bottom: 6, trailing: RadarScale.gutter))
                .listRowSeparator(.hidden)
                ForEach(Array(tracks.enumerated()), id: \.offset) { i, t in
                    let current = i == player.queue.index
                    let model = TrackRowModel(track: t, artist: catalog.artistName(for: t), isCurrent: current,
                                              isPlaying: current && player.isPlaying, isSaved: library.isSaved(t.id))
                    TrackRow(model: model, art: catalog.art(for: t),
                             actions: TrackRowActions(play: { player.jump(to: i) }, toggleSave: { _ = library.toggleSave(t.id) },
                                                      addToPlaylist: {}, openDetails: {}))
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: RadarScale.gutter, bottom: 0, trailing: RadarScale.gutter))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { player.removeAt(i) } label: { Label("Remove", systemImage: "trash") }
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

/// Wide windows: a bar along the bottom instead of the mini player.
struct TransportBar: View {
    let art: Namespace.ID
    @Environment(PlayerStore.self) private var player
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let catalog = DemoCatalog.shared
        HStack(spacing: 16) {
            if let t = player.current {
                Button { withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.5, bounce: 0)) { player.expanded = true } } label: {
                    HStack(spacing: 12) {
                        ArtworkView(catalog.art(for: t)).frame(width: 52, height: 52)
                            .matchedGeometryEffect(id: "art", in: art, isSource: !player.expanded)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t.title).font(RadarFont.ui(15, .semibold)).lineLimit(1)
                            Text(player.isDemoPlayback ? "Demo playback" : catalog.artistName(for: t))
                                .font(RadarFont.body(12, .regular, relativeTo: .caption)).foregroundStyle(Color.radarText2).lineLimit(1)
                        }
                        .frame(maxWidth: 220, alignment: .leading)
                    }
                }
                .buttonStyle(NavPressStyle())
                .accessibilityLabel("Open player, \(t.title)")
                TransportControls(big: false).frame(maxWidth: 300)
                VStack(spacing: 2) {
                    WaveformScrubber(peaks: DemoCatalog.rawWaveform(trackId: t.id), progress: player.fraction,
                                     duration: player.duration, height: 36) { player.seek(fraction: $0) }
                    ScrubTimes(progress: player.fraction, duration: player.duration)
                }
                Button { player.dockOpen.toggle() } label: {
                    RadarIcon(.queue, size: 24).foregroundStyle(player.dockOpen ? Color.radarAccentText : Color.radarText)
                        .frame(width: RadarScale.touch, height: RadarScale.touch)
                }
                .buttonStyle(NavPressStyle())
                .accessibilityLabel("Queue")
            } else {
                Text("Nothing playing").font(RadarFont.body(13, .regular, relativeTo: .footnote)).foregroundStyle(Color.radarText3)
                Spacer()
            }
        }
        .padding(.horizontal, RadarScale.gutter).padding(.vertical, 10)
        .background(Color.radarSurface)
        .overlay(alignment: .top) { Rectangle().fill(Color.radarLine).frame(height: 1) }
        .foregroundStyle(Color.radarText)
    }
}
