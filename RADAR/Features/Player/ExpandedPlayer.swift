import SwiftUI

/// Full player. Compact: artwork page and Queue page under tabs. Wide (`usesTwoPanePlayer`):
/// artwork + controls on the left, the queue always visible on the right.
/// Pull down (anywhere on the header or artwork) to close; swipe the artwork sideways to skip.
struct ExpandedPlayer: View {
    let art: Namespace.ID
    @Environment(PlayerStore.self) private var player
    @Environment(LibraryStore.self) private var library
    @Environment(\.radarLayout) private var layout
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var page = "now"
    @State private var pull: CGFloat = 0
    @State private var scrub: Double?

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                header
                if layout.usesTwoPanePlayer {
                    HStack(spacing: 0) {
                        nowPlaying.frame(maxWidth: .infinity)
                        Rectangle().fill(Color.radarLine).frame(width: 1)
                        QueueList().frame(maxWidth: 420)
                    }
                } else {
                    RadarTabs(items: [.init("now", "Now playing"), .init("queue", "Queue", count: player.queue.ids.count)], selection: $page)
                    if page == "now" { nowPlaying.transition(.opacity) } else { QueueList().transition(.opacity) }
                }
            }
            .background(Color.radarBg.ignoresSafeArea())
            .offset(y: SheetDismiss.rubber(pull) + max(pull, 0))
            .gesture(pullDown(height: geo.size.height))
        }
        .foregroundStyle(Color.radarText)
        .transition(.move(edge: .bottom))
    }

    private func close() {
        withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.5, bounce: 0)) { player.expanded = false; pull = 0 }
    }

    private func pullDown(height: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 14, coordinateSpace: .global)
            .onChanged { v in
                if abs(v.translation.height) > abs(v.translation.width) { pull = v.translation.height }
            }
            .onEnded { v in
                if SheetDismiss.shouldDismiss(translation: v.translation.height, predicted: v.predictedEndTranslation.height, height: height) {
                    close()
                } else {
                    withAnimation(.spring(duration: 0.5, bounce: 0)) { pull = 0 }
                }
            }
    }

    private var header: some View {
        HStack {
            Button(action: close) {
                RadarIcon(.chevronDown, size: 26).frame(width: RadarScale.touch, height: RadarScale.touch)
            }
            .buttonStyle(NavPressStyle())
            .accessibilityLabel("Close player")
            Spacer()
            Text(player.isDemoPlayback ? "Demo playback" : "Now playing").radarReadout()
            Spacer()
            Color.clear.frame(width: RadarScale.touch, height: RadarScale.touch)
        }
        .padding(.horizontal, 8)
        .accessibilityAction(.escape) { close() }
    }

    @ViewBuilder
    private var nowPlaying: some View {
        if let t = player.current {
            let catalog = DemoCatalog.shared
            ScrollView {
                VStack(spacing: 22) {
                    ArtworkView(catalog.art(for: t))
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: 420)
                        .matchedGeometryEffect(id: "art", in: art, isSource: player.expanded)
                        .artFX()
                        .gesture(DragGesture(minimumDistance: 20).onEnded { v in
                            switch PlayerSwipe.decide(translation: v.translation, predicted: v.predictedEndTranslation) {
                            case .next: player.next()
                            case .previous: player.previous()
                            default: break
                            }
                        })
                        .accessibilityHidden(true)

                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(t.title).radarTitle(.medium, lines: 2)
                            Text(catalog.artistName(for: t)).font(RadarFont.body(15, .regular, relativeTo: .body)).foregroundStyle(Color.radarText2)
                        }
                        Spacer(minLength: 8)
                        Button { _ = library.toggleSave(t.id) } label: {
                            RadarIcon(library.isSaved(t.id) ? .heartFill : .heart, size: 26)
                                .foregroundStyle(library.isSaved(t.id) ? Color.radarSignalText : Color.radarText)
                                .frame(width: RadarScale.touch, height: RadarScale.touch)
                        }
                        .buttonStyle(NavPressStyle())
                        .accessibilityLabel(library.isSaved(t.id) ? "Remove from Saved" : "Save")
                    }
                    .sensoryFeedback(.success, trigger: library.isSaved(t.id)) { _, new in new && Haptics.isEnabled }

                    if let error = player.playbackError {
                        Text(error).font(RadarFont.body(13, .regular, relativeTo: .footnote)).foregroundStyle(Color.radarSignalText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(spacing: 6) {
                        WaveformScrubber(peaks: DemoCatalog.rawWaveform(trackId: t.id), progress: scrub ?? player.fraction,
                                         duration: player.duration, height: 56,
                                         onScrubChange: { scrub = $0 }, onSeek: { scrub = nil; player.seek(fraction: $0) })
                        ScrubTimes(progress: scrub ?? player.fraction, duration: player.duration)
                    }
                    TransportControls()
                }
                .padding(.horizontal, RadarScale.gutter)
                .padding(.vertical, 12)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        } else {
            Spacer()
        }
    }
}
