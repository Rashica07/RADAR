import SwiftUI

/// House style for native sheets: system detents and drag physics (interruptible, velocity-aware),
/// RADAR surface behind, grabber visible.
extension View {
    func radarSheet(detents: Set<PresentationDetent> = [.medium, .large]) -> some View {
        self
            .presentationDetents(detents)
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.radarBg)
            .presentationCornerRadius(0)
            .presentationBackgroundInteraction(.disabled)
    }
}

/// Title bar used inside sheets and sub-pages.
struct SheetHeader: View {
    let title: String
    var kicker: String?
    var back: (() -> Void)?
    var close: (() -> Void)?

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if let back {
                Button(action: back) { RadarIcon(.chevronLeft, size: 20).frame(width: 44, height: 44).contentShape(Rectangle()) }
                    .buttonStyle(.plain).accessibilityLabel("Back")
            }
            VStack(alignment: .leading, spacing: 2) {
                if let kicker { Text(kicker).radarReadout() }
                Text(title).font(RadarFont.display(30, .black, relativeTo: .title)).textCase(.uppercase)
                    .foregroundStyle(Color.radarText).lineLimit(2).minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer(minLength: 0)
            if let close {
                Button(action: close) { RadarIcon(.x, size: 20).frame(width: 44, height: 44).contentShape(Rectangle()) }
                    .buttonStyle(.plain).accessibilityLabel("Close")
            }
        }
        .padding(.horizontal, RadarScale.gutter).padding(.top, 22)
    }
}

/// What "Demo data" means, in plain words. Honest about what is simulated and what is real.
struct AboutDemoDataSheet: View {
    var dismiss: () -> Void

    static let points: [(title: String, body: String)] = [
        ("Catalogue and charts are sample data", "Tracks, artists, plays and chart positions are invented to show how RADAR works. Nothing here is a real ranking."),
        ("Downloads are simulated", "Tapping download shows progress and a status, but no file is fetched or stored."),
        ("Your own files are real", "Audio you import from this device is copied into RADAR and plays from there."),
        ("Nothing leaves your phone", "Saved tracks, playlists and settings stay on this device.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SheetHeader(title: "About demo data", kicker: "Read me", close: dismiss)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(Self.points.enumerated()), id: \.offset) { _, p in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(p.title).font(RadarFont.ui(16, .bold, relativeTo: .body)).foregroundStyle(Color.radarText)
                            Text(p.body).font(RadarFont.body(15, .regular, relativeTo: .body)).foregroundStyle(Color.radarText2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, RadarScale.gutter).padding(.bottom, 24)
            }
        }
        .background(Color.radarBg)
    }
}

/// Playlist picker for "Add to playlist": a list, with "New playlist" first.
struct AddToPlaylistSheet: View {
    struct Choice: Identifiable, Equatable {
        let id: String
        let title: String
        let count: Int
        let alreadyContains: Bool
        let art: ArtSpec
    }

    let trackTitle: String
    let choices: [Choice]
    var onPick: (Choice) -> Void
    var onCreate: () -> Void
    var dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SheetHeader(title: "Add to playlist", kicker: trackTitle, close: dismiss)
            List {
                Button(action: onCreate) {
                    HStack(spacing: 12) {
                        RadarIcon(.plus, size: 22).frame(width: 52, height: 52).background(Color.radarSurface2)
                        Text("New playlist").font(RadarFont.ui(16, .semibold)).foregroundStyle(Color.radarAccentText)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(RowPressStyle()).listRowBackground(Color.clear)
                ForEach(choices) { c in
                    Button { onPick(c) } label: {
                        HStack(spacing: 12) {
                            ArtworkView(c.art).frame(width: 52, height: 52)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(c.title).font(RadarFont.ui(16, .semibold)).foregroundStyle(Color.radarText).lineLimit(1)
                                Text(c.alreadyContains ? "Already added" : Format.plural(c.count, "track"))
                                    .font(RadarFont.body(13, .regular, relativeTo: .footnote)).foregroundStyle(Color.radarText2)
                            }
                            Spacer()
                            if c.alreadyContains { RadarIcon(.check, size: 18).foregroundStyle(Color.radarAccentText) }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(RowPressStyle()).listRowBackground(Color.clear)
                    .accessibilityLabel("\(c.title), \(c.alreadyContains ? "already added" : Format.plural(c.count, "track"))")
                }
            }
            .listStyle(.plain)
        }
        .background(Color.radarBg)
    }
}

/// Empty / offline state: a quiet pulse, one line of what happened, one way out.
struct NoSignalCard: View {
    var title = "No signal"
    var message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                PingBlip(size: 8)
                Text(title).radarReadout()
            }
            Text(message).font(RadarFont.body(16, .regular, relativeTo: .body)).foregroundStyle(Color.radarText2)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action).buttonStyle(.radar(.outline, size: .md))
            }
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.radarSurface)
        .overlay { Rectangle().strokeBorder(Color.radarLine, lineWidth: 1) }
        .accessibilityElement(children: .combine)
    }
}
