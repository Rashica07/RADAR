import SwiftUI

/// Spotify-style mini player: a rounded plate tinted from the cover, white ink, a hairline progress
/// line at the bottom. Tap opens the full player; the buttons act in place.
struct MiniPlayerBar: View {
    @Environment(PlayerStore.self) private var player
    @Environment(LibraryStore.self) private var library
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        if let track = player.current {
            let catalog = DemoCatalog.shared
            let art = catalog.art(for: track)
            let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Button { withAnimation(RadarUI.Motion.layer) { player.expanded = true } } label: {
                        HStack(spacing: 10) {
                            ArtworkView(art).frame(width: 40, height: 40).clipShape(.rect(cornerRadius: 6))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(track.title).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                                Text(player.isDemoPlayback ? "Demo playback" : catalog.artistName(for: track))
                                    .font(.system(size: 12)).opacity(0.7).lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open player, \(track.title)")
                    Button { _ = library.toggleSave(track.id) } label: {
                        Image(systemName: library.isSaved(track.id) ? "heart.fill" : "heart")
                            .font(.system(size: 18)).frame(width: 36, height: 40)
                            .foregroundStyle(library.isSaved(track.id) ? Color.radarSignal : .white)
                    }
                    .accessibilityLabel(library.isSaved(track.id) ? "Remove from Saved" : "Save")
                    Button { player.toggle() } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20)).frame(width: 36, height: 40)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
                }
                .padding(.horizontal, 8).padding(.top, 8).padding(.bottom, 6)
                Capsule().fill(.white.opacity(0.25)).frame(height: 2).padding(.horizontal, 10).padding(.bottom, 6)
                    .overlay(alignment: .leading) {
                        GeometryReader { g in Capsule().fill(.white).frame(width: g.size.width * player.fraction) }
                            .frame(height: 2).padding(.horizontal, 10).padding(.bottom, 6)
                    }
            }
            .foregroundStyle(.white)
            .background(art.palette.tint, in: shape)
            .overlay(shape.strokeBorder(RadarUI.Hairline.color(scheme, emphasis: 1.4), lineWidth: 1))
            .padding(.horizontal, 14).padding(.bottom, 4)
            .animation(RadarUI.Motion.settle, value: track.id)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

/// Full-screen player over a gradient from the cover's colour. Drag down to close.
struct NowPlayingScreen: View {
    @Environment(PlayerStore.self) private var player
    @Environment(LibraryStore.self) private var library
    @State private var scrubbing: Double?
    @State private var pull: CGFloat = 0
    @State private var showQueue = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let track = player.current {
                    let catalog = DemoCatalog.shared
                    let art = catalog.art(for: track)
                    LinearGradient(colors: [art.palette.tint, art.palette.tint.opacity(0.55), Color.radarBg], startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.6), value: track.id)
                    VStack(spacing: 0) {
                        topBar(track)
                        Spacer(minLength: 12)
                        ArtworkView(art)
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(.rect(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
                            .padding(.horizontal, 24)
                            .frame(maxWidth: 460)
                            .scaleEffect(player.isPlaying ? 1 : 0.9)
                            .animation(RadarUI.Motion.settle, value: player.isPlaying)
                            .accessibilityHidden(true)
                        Spacer(minLength: 16)
                        titleRow(track, catalog: catalog)
                        scrubber
                        controls
                        bottomRow(track)
                    }
                    .padding(.horizontal, 24).padding(.bottom, 12)
                    .frame(maxWidth: 560)
                } else {
                    Color.radarBg.ignoresSafeArea()
                }
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white)
            .environment(\.colorScheme, .dark)
            .offset(y: max(pull, 0))
            .gesture(
                DragGesture(minimumDistance: 14)
                    .onChanged { v in if v.translation.height > 0, abs(v.translation.height) > abs(v.translation.width) { pull = v.translation.height } }
                    .onEnded { v in
                        if SheetDismiss.shouldDismiss(translation: v.translation.height, predicted: v.predictedEndTranslation.height, height: geo.size.height) {
                            close()
                        } else { withAnimation(RadarUI.Motion.settle) { pull = 0 } }
                    }
            )
        }
        .background(Color.radarBg.ignoresSafeArea())
        .sheet(isPresented: $showQueue) { QueueSheet() }
        .transition(.move(edge: .bottom))
    }

    private func close() {
        withAnimation(RadarUI.Motion.layer) { player.expanded = false; pull = 0 }
    }

    private func topBar(_ track: Track) -> some View {
        HStack {
            Button(action: close) { Image(systemName: "chevron.down").font(.system(size: 18, weight: .semibold)).frame(width: 44, height: 44) }
                .accessibilityLabel("Close player")
            Spacer()
            VStack(spacing: 1) {
                Text(player.isDemoPlayback ? "DEMO PLAYBACK" : "NOW PLAYING").font(.system(size: 10, weight: .bold)).kerning(1.6).opacity(0.7)
                Text(DemoCatalog.shared.artistName(for: track)).font(.system(size: 13, weight: .semibold)).lineLimit(1)
            }
            Spacer()
            Menu { TrackMenu(track: track) } label: { Image(systemName: "ellipsis").font(.system(size: 18, weight: .semibold)).frame(width: 44, height: 44) }
        }
        .padding(.top, 4)
    }

    private func titleRow(_ track: Track, catalog: DemoCatalog) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title).font(.system(size: 24, weight: .bold)).lineLimit(1).minimumScaleFactor(0.7)
                Text(catalog.artistName(for: track)).font(.system(size: 16)).opacity(0.7).lineLimit(1)
                if let error = player.playbackError {
                    Label(error, systemImage: "exclamationmark.triangle").font(.footnote).foregroundStyle(Color.radarSignal)
                }
            }
            Spacer(minLength: 8)
            Button { _ = library.toggleSave(track.id) } label: {
                Image(systemName: library.isSaved(track.id) ? "heart.fill" : "heart").font(.system(size: 24))
                    .foregroundStyle(library.isSaved(track.id) ? Color.radarSignal : .white)
                    .frame(width: 44, height: 44)
                    .symbolEffect(.bounce, value: library.isSaved(track.id))
            }
            .sensoryFeedback(.success, trigger: library.isSaved(track.id)) { _, new in new }
            .accessibilityLabel(library.isSaved(track.id) ? "Remove from Saved" : "Save")
        }
    }

    private var scrubber: some View {
        VStack(spacing: 0) {
            ScrubBar(fraction: scrubbing ?? player.fraction, onChange: { scrubbing = $0 }, onCommit: { player.seek(fraction: $0); scrubbing = nil })
            HStack {
                Text(Format.time((scrubbing ?? player.fraction) * player.duration))
                Spacer()
                Text("-" + Format.time(player.duration - (scrubbing ?? player.fraction) * player.duration))
            }
            .font(.system(size: 12).monospacedDigit()).opacity(0.7)
        }
        .padding(.top, 8)
    }

    private var controls: some View {
        HStack {
            Button { player.toggleShuffle() } label: {
                Image(systemName: "shuffle").font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(player.shuffle ? Color.radarAccent : .white).frame(width: 48, height: 48)
            }.accessibilityLabel("Shuffle").accessibilityAddTraits(player.shuffle ? .isSelected : [])
            Spacer()
            Button { player.previous() } label: { Image(systemName: "backward.fill").font(.system(size: 28)).frame(width: 56, height: 56) }
                .accessibilityLabel("Previous track")
            Spacer()
            Button { player.toggle() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill").font(.system(size: 30))
                    .foregroundStyle(Color.radarCharcoal)
                    .frame(width: 70, height: 70).background(Circle().fill(.white))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(PressScale())
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
            Spacer()
            Button { player.next() } label: { Image(systemName: "forward.fill").font(.system(size: 28)).frame(width: 56, height: 56) }
                .accessibilityLabel("Next track")
            Spacer()
            Button { player.cycleRepeat() } label: {
                Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat").font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(player.repeatMode == .off ? .white : Color.radarAccent).frame(width: 48, height: 48)
            }.accessibilityLabel("Repeat \(player.repeatMode.rawValue)")
        }
        .padding(.top, 4)
        .sensoryFeedback(.selection, trigger: player.repeatMode)
        .sensoryFeedback(.selection, trigger: player.shuffle)
    }

    private func bottomRow(_ track: Track) -> some View {
        HStack {
            if let item = Optional("\(track.title) · \(DemoCatalog.shared.artistName(for: track))") {
                ShareLink(item: item) { Image(systemName: "square.and.arrow.up").font(.system(size: 18)).frame(width: 44, height: 44) }
            }
            Spacer()
            Button { showQueue = true } label: { Image(systemName: "list.bullet").font(.system(size: 20)).frame(width: 44, height: 44) }
                .accessibilityLabel("Queue")
        }
        .padding(.top, 4)
    }
}

/// Buttons ease to 0.97 while pressed.
struct PressScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.94 : 1).animation(RadarUI.Motion.settle, value: configuration.isPressed)
    }
}

/// When far enough or flicked hard enough, a pull-down closes the player.
enum SheetDismiss {
    static func shouldDismiss(translation: CGFloat, predicted: CGFloat, height: CGFloat) -> Bool {
        guard translation > 0 else { return false }
        return translation > height * 0.25 || (translation > 40 && predicted > height * 0.45)
    }
}

private struct QueueSheet: View {
    @Environment(PlayerStore.self) private var player
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            QueueList()
                .navigationTitle("Queue")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
        .tint(Color.radarAccentText)
    }
}

struct QueueList: View {
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
