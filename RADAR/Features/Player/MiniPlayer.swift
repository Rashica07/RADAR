import SwiftUI

/// Compact player docked above the navigation. Tap or swipe up to expand; swipe sideways to skip
/// (the row follows the finger, then springs back). Buttons and VoiceOver actions cover the same.
struct MiniPlayer: View {
    let art: Namespace.ID
    @Environment(PlayerStore.self) private var player
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drag: CGFloat = 0
    @ScaledMetric(relativeTo: .body) private var artSize: CGFloat = 44

    var body: some View {
        if let track = player.current {
            let catalog = DemoCatalog.shared
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    ArtworkView(catalog.art(for: track))
                        .frame(width: artSize, height: artSize)
                        .matchedGeometryEffect(id: "art", in: art, isSource: !player.expanded)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title).font(RadarFont.ui(15, .semibold)).lineLimit(1)
                        Text(player.isDemoPlayback ? "Demo playback" : catalog.artistName(for: track))
                            .font(RadarFont.body(12, .regular, relativeTo: .caption)).foregroundStyle(Color.radarText2).lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    Button { player.toggle() } label: {
                        RadarIcon(player.isPlaying ? .pause : .play, size: 24)
                            .frame(width: RadarScale.touch, height: RadarScale.touch)
                    }
                    .buttonStyle(NavPressStyle())
                    .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
                    Button { player.next() } label: {
                        RadarIcon(.next, size: 22).frame(width: RadarScale.touch, height: RadarScale.touch)
                    }
                    .buttonStyle(NavPressStyle())
                    .accessibilityLabel("Next track")
                }
                .padding(.horizontal, RadarScale.gutter)
                .padding(.vertical, 8)
                .offset(x: drag)
                .contentShape(Rectangle())
                .onTapGesture { expand() }
                .gesture(swipe)

                ProgressStrip(fraction: player.fraction)
            }
            .background(Color.radarSurface)
            .overlay(alignment: .top) { Rectangle().fill(Color.radarLine).frame(height: 1) }
            .foregroundStyle(Color.radarText)
            .accessibilityElement(children: .contain)
            .accessibilityAction(named: "Expand player") { expand() }
            .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .bottom)))
        }
    }

    private func expand() {
        withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.5, bounce: 0)) { player.expanded = true }
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { v in
                if abs(v.translation.width) > abs(v.translation.height) { drag = v.translation.width * 0.6 }
            }
            .onEnded { v in
                switch PlayerSwipe.decide(translation: v.translation, predicted: v.predictedEndTranslation) {
                case .next: player.next()
                case .previous: player.previous()
                case .expand: expand()
                case .none: break
                }
                withAnimation(.spring(duration: 0.5, bounce: 0)) { drag = 0 }
            }
    }
}

struct ProgressStrip: View {
    let fraction: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.radarLine)
                Rectangle().fill(Color.radarAccent).frame(width: geo.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: 2)
        .accessibilityHidden(true)
    }
}
