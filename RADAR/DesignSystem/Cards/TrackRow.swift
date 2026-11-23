import SwiftUI

/// A track in a list. Designed for `List` rows: swipe from the leading edge to play next, from
/// the trailing edge to save (full swipe commits), press and hold for a context menu with a
/// large cover preview — all the system's own gestures, haptics and VoiceOver actions.
struct TrackRow: View {
    let model: TrackRowModel
    let art: ArtSpec
    let actions: TrackRowActions

    @ScaledMetric(relativeTo: .body) private var artSize: CGFloat = 52
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var showsDuration: Bool { sizeClass == .regular && !typeSize.isAccessibilitySize }

    var body: some View {
        HStack(spacing: 0) {
            if let rank = model.rank { rankColumn(rank) }

            Button(action: actions.play) {
                HStack(spacing: 12) {
                    cover
                    VStack(alignment: .leading, spacing: 3) {
                        Text(model.title)
                            .font(RadarFont.ui(16, .semibold, relativeTo: .body))
                            .foregroundStyle(model.isCurrent ? Color.radarAccentText : Color.radarText)
                            .lineLimit(typeSize.isAccessibilitySize ? 2 : 1)
                        HStack(spacing: 6) {
                            if model.isExplicit { ExplicitFlag() }
                            Text(model.artist).lineLimit(1)
                        }
                        .font(RadarFont.body(13, .regular, relativeTo: .footnote))
                        .foregroundStyle(Color.radarText2)
                    }
                    Spacer(minLength: 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(RowPressStyle())
            .accessibilityLabel(model.accessibilityLabel)
            .accessibilityHint(model.playHint)

            if showsDuration {
                Text(model.duration).font(RadarFont.body(13, .medium, relativeTo: .footnote)).monospacedDigit()
                    .foregroundStyle(Color.radarText3).frame(width: 48, alignment: .trailing)
            }
            if let toggle = actions.toggleSave { SaveButton(isSaved: model.isSaved, title: model.title, action: toggle) }
            moreMenu
        }
        .padding(.vertical, 6)
        .frame(minHeight: 60)
        .overlay(alignment: .leading) {
            if model.isCurrent {
                Capsule().fill(Color.radarAccent).frame(width: 3).padding(.vertical, 12).offset(x: -RadarScale.gutter)
                    .transition(.scale(scale: 0.2, anchor: .center).combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottomLeading) {
            if let p = model.downloadProgress {
                GeometryReader { proxy in
                    Rectangle().fill(Color.radarAccent).frame(width: proxy.size.width * p, height: 2)
                        .animation(.smooth(duration: 0.25), value: p)
                }
                .frame(height: 2).accessibilityHidden(true)
            }
        }
        .animation(.snappy(duration: 0.3), value: model.isCurrent)
        .accessibilityElement(children: .contain)
    }

    private var cover: some View {
        ArtworkView(art)
            .frame(width: artSize, height: artSize)
            .overlay {
                if model.isCurrent {
                    ZStack {
                        Color.black.opacity(0.6)
                        EQBars(playing: model.isPlaying, width: 20, height: 18)
                    }
                    .transition(.opacity)
                }
            }
            .clipShape(Rectangle())
    }

    private func rankColumn(_ rank: Int) -> some View {
        VStack(spacing: 5) {
            Text("\(rank)")
                .font(RadarFont.display(34, .black, relativeTo: .title))
                .monospacedDigit().contentTransition(.numericText())
                .foregroundStyle(rank == 1 ? Color.radarAccentText : Color.radarText)
            if let move = model.move { MoveIndicator(move) }
        }
        .frame(width: 52)
        .accessibilityHidden(true)       // folded into the row's label
    }

    private var moreMenu: some View {
        Menu {
            TrackMenuItems(model: model, actions: actions)
        } label: {
            RadarIcon(.more, size: 20).foregroundStyle(Color.radarText3).frame(width: 44, height: 44).contentShape(Rectangle())
        }
        .accessibilityLabel("More options for \(model.title)")
    }
}

/// Heart toggle: spring bounce on change, selection haptic.
private struct SaveButton: View {
    let isSaved: Bool
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RadarIcon(isSaved ? .heartFill : .heart, size: 22)
                .foregroundStyle(isSaved ? Color.radarAccentText : Color.radarText3)
                .keyframeAnimator(initialValue: 1.0, trigger: isSaved) { view, scale in view.scaleEffect(scale) } keyframes: { _ in
                    SpringKeyframe(1.3, duration: 0.14, spring: .bouncy)
                    SpringKeyframe(1.0, duration: 0.3, spring: .bouncy)
                }
                .frame(width: 44, height: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSaved)
        .accessibilityLabel(isSaved ? "Remove \(title) from Library" : "Save \(title) to Library")
    }
}

/// Soft highlight on press instead of a colour jump.
struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.radarSurface.opacity(0.9) : .clear)
            .scaleEffect(configuration.isPressed ? 0.985 : 1, anchor: .leading)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

/// The same actions as buttons, for the "…" menu and the long-press context menu.
struct TrackMenuItems: View {
    let model: TrackRowModel
    let actions: TrackRowActions
    var body: some View {
        Button { actions.playNext() } label: { Label("Play next", systemImage: "text.line.first.and.arrowtriangle.forward") }
        Button { actions.enqueue() } label: { Label("Add to queue", systemImage: "text.append") }
        if let toggle = actions.toggleSave {
            Button { toggle() } label: {
                Label(model.isSaved ? "Remove from Library" : "Save to Library", systemImage: model.isSaved ? "heart.slash" : "heart")
            }
        }
        if let add = actions.addToPlaylist { Button { add() } label: { Label("Add to playlist", systemImage: "plus") } }
        if let details = actions.openDetails { Button { details() } label: { Label("Track details", systemImage: "info.circle") } }
    }
}

extension View {
    /// Native swipe actions + press-and-hold menu with a cover preview + VoiceOver actions.
    func trackActions(_ model: TrackRowModel, art: ArtSpec, _ actions: TrackRowActions) -> some View {
        self
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button { actions.playNext() } label: { Label("Play next", systemImage: "text.line.first.and.arrowtriangle.forward") }
                    .tint(Color.radarSurface3)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: actions.toggleSave != nil) {
                if let toggle = actions.toggleSave {
                    Button { toggle() } label: {
                        Label(model.isSaved ? "Unsave" : "Save", systemImage: model.isSaved ? "heart.slash" : "heart.fill")
                    }
                    .tint(model.isSaved ? Color.radarSurface3 : Color.radarAccent)
                }
            }
            .contextMenu {
                TrackMenuItems(model: model, actions: actions)
            } preview: {
                TrackPreview(model: model, art: art)
            }
            .accessibilityAction(named: "Play next") { actions.playNext() }
            .accessibilityAction(named: "Add to queue") { actions.enqueue() }
            .accessibilityAction(named: model.isSaved ? "Remove from Library" : "Save to Library") { actions.toggleSave?() }
    }
}

private struct TrackPreview: View {
    let model: TrackRowModel
    let art: ArtSpec
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ArtworkView(art).artFX().frame(width: 260, height: 260)
            Text(model.title).font(RadarFont.display(28, .black)).textCase(.uppercase).lineLimit(2)
            Text(model.artist).font(RadarFont.ui(15, .semibold)).foregroundStyle(Color.radarText2)
        }
        .padding(16).frame(width: 292, alignment: .leading).background(Color.radarBg)
    }
}

/// Loading placeholder with the same metrics as `TrackRow`.
struct TrackRowSkeleton: View {
    var rank = false
    var index = 0
    @ScaledMetric(relativeTo: .body) private var artSize: CGFloat = 52
    var body: some View {
        HStack(spacing: 12) {
            if rank { SkeletonBlock().frame(width: 22, height: 30).frame(width: 52) }
            SkeletonBlock().frame(width: artSize, height: artSize)
            VStack(alignment: .leading, spacing: 8) {
                SkeletonBlock().frame(height: 14).frame(maxWidth: .infinity, alignment: .leading).scaleEffect(x: 0.58 - Double(index % 3) * 0.09, anchor: .leading)
                SkeletonBlock().frame(height: 11).frame(maxWidth: .infinity, alignment: .leading).scaleEffect(x: 0.34 + Double(index % 4) * 0.06, anchor: .leading)
            }
        }
        .padding(.vertical, 6).frame(minHeight: 60)
        .accessibilityElement().accessibilityLabel("Loading")
    }
}
