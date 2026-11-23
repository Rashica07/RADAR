#if DEBUG
import SwiftUI

/// Developer gallery of the design-system primitives built so far (Phase 3 Step 3): artwork,
/// FX, type and layout components. Lives in the Layout Lab until the real "Art lab" screen
/// replaces it.
struct DesignGalleryView: View {
    @State private var tab = "saved"
    @State private var burst = 0
    @State private var glitch = 0
    @State private var playing = true
    @State private var split = false
    @State private var saved: Set<String> = []
    @State private var current = ""
    @State private var toasts = ToastCenter()
    @State private var showAbout = false
    @State private var showPicker = false
    @State private var progress = 0.32

    private let styles = ArtStyle.allCases

    var body: some View {
        content
            .toastHost(toasts)
            .sheet(isPresented: $showAbout) { AboutDemoDataSheet { showAbout = false }.radarSheet() }
            .sheet(isPresented: $showPicker) {
                AddToPlaylistSheet(trackTitle: "Autobahn Bloom", choices: [
                    .init(id: "a", title: "Late night", count: 12, alreadyContains: false, art: ArtSpec(key: "a")),
                    .init(id: "b", title: "Run", count: 8, alreadyContains: true, art: ArtSpec(key: "b"))
                ], onPick: { _ in showPicker = false; toasts.show("Added", icon: .check) }, onCreate: { showPicker = false }, dismiss: { showPicker = false })
                .radarSheet()
            }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 26) {
            SectionHeader("Design gallery", idx: "DS", kicker: "Step 3 · primitives", moving: true,
                          sub: "Artwork, FX, type and layout components, drawn natively.")

            block("Artwork · 8 styles") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                    ForEach(Array(styles.enumerated()), id: \.offset) { i, style in
                        ArtworkView(ArtSpec(seed: UInt32(7 + i * 31), palette: ArtPalette.allCases[(i * 3) % 10], style: style))
                            .aspectRatio(1, contentMode: .fit).artFX()
                    }
                }
            }

            block("FX · tap to replay") {
                HStack(alignment: .top, spacing: 12) {
                    ArtworkView(ArtSpec(seed: 7, palette: .ember, style: .rings)).frame(width: 110, height: 110).artFX()
                        .fxBurst(key: burst).fxSplit(split)
                        .onTapGesture { burst += 1 }
                    VStack(alignment: .leading, spacing: 10) {
                        GlitchText(text: "Find what's moving", font: RadarFont.display(30, .black), trigger: glitch)
                            .onTapGesture { glitch += 1 }
                        HStack(spacing: 16) {
                            EQBars(playing: playing, width: 24, height: 24).onTapGesture { playing.toggle() }
                            PingBlip(size: 10)
                            Toggle("Split", isOn: $split).labelsHidden()
                        }
                        SkeletonBlock().frame(height: 28)
                    }
                }
            }

            block("Tabs · readout · flags") {
                RadarTabs(items: [.init("saved", "Saved", count: 4), .init("lists", "Playlists", count: 2),
                                  .init("recent", "Recent"), .init("local", "Local"), .init("off", "Offline")],
                          selection: $tab)
                Readout([.text("Week 47"), .separator, .strong("12 plays"), .separator, .text("IT")])
                HStack(spacing: 10) { NewFlag(); ExplicitFlag(); DemoBadge(action: {}); SourceTag(source: .catalog, name: "Demo Catalog") }
                HStack(spacing: 14) {
                    StatusLabel(status: .downloaded)
                    MoveIndicator(delta: 2, previous: 3); MoveIndicator(delta: -1, previous: 3); MoveIndicator(.new); MoveIndicator(.unchanged)
                    Sparkline(data: [1, 3, 2, 5, 4, 7])
                }
            }

            block("Buttons") {
                HStack(spacing: 10) {
                    Button("Play") {}.buttonStyle(.radar(.primary))
                    Button("Share") {}.buttonStyle(.radar(.outline))
                    Button("Open") {}.buttonStyle(.radarCTA)
                }
                HStack(spacing: 10) {
                    Button("Afrobeats") {}.buttonStyle(.radarTag(on: true))
                    Button("House") {}.buttonStyle(.radarTag())
                    Button("Clear") {}.buttonStyle(.radarTag(ghost: true))
                    Button("Jazz") {}.buttonStyle(.radarSlash)
                }
                Button("Save to library") {}.buttonStyle(.radar(.primary, size: .lg, block: true))
            }

            block("Rows · swipe, press and hold") {
                let catalog = DemoCatalog.shared
                List {
                    ForEach(catalog.chart(country: "GLOBAL", window: .week, limit: 4)) { entry in
                        let t = entry.track
                        let model = TrackRowModel(track: t, artist: catalog.artistName(for: t), entry: entry,
                                                  isCurrent: current == t.id, isPlaying: true, isSaved: saved.contains(t.id),
                                                  downloadProgress: t.id == catalog.chart(country: "GLOBAL", window: .week, limit: 1).first?.track.id ? 0.6 : nil)
                        let art = catalog.art(for: t)
                        let actions = TrackRowActions(play: { current = t.id }, toggleSave: {
                            if saved.contains(t.id) { saved.remove(t.id) } else { saved.insert(t.id) }
                        }, addToPlaylist: {}, openDetails: {})
                        TrackRow(model: model, art: art, actions: actions)
                            .trackActions(model, art: art, actions)
                            .listRowBackground(Color.clear).listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                    TrackRowSkeleton(rank: true, index: 1).listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                }
                .listStyle(.plain).scrollDisabled(true).frame(height: 5 * 72)
            }

            block("Tiles · rail") {
                let catalog = DemoCatalog.shared
                Rail(items: catalog.newReleases(limit: 6)) { t in
                    Tile(title: t.title, subtitle: catalog.artistName(for: t), art: catalog.art(for: t), badge: "New")
                }
                .frame(height: 210).padding(.horizontal, -RadarScale.gutter)
            }

            block("Poster · Band · Mix") {
                let catalog = DemoCatalog.shared
                let entries = catalog.chart(country: "GLOBAL", window: .week, limit: 3)
                HStack(spacing: 10) {
                    ForEach(entries) { e in
                        Poster(rank: e.rank, title: e.track.title, subtitle: catalog.artistName(for: e.track), art: catalog.art(for: e.track))
                    }
                }
                Band(title: "Jazz", detail: "142 tracks", art: ArtSpec(key: "genre-jazz"))
                Mix(title: "Late night mix", subtitle: "4 tracks", arts: entries.map { catalog.art(for: $0.track) } + [ArtSpec(key: "x")])
                    .frame(width: 160)
            }

            block("Overlays") {
                HStack(spacing: 8) {
                    Button("Toast") { toasts.show("Saved to Library", icon: .heartFill) }.buttonStyle(.radarTag())
                    Button("About demo data") { showAbout = true }.buttonStyle(.radarTag())
                    Button("Add to playlist") { showPicker = true }.buttonStyle(.radarTag())
                }
                NoSignalCard(message: "Can't reach the catalogue. Showing what is saved on this device.", actionTitle: "Try again") { toasts.show("Retrying…") }
            }

            block("Waveform scrubber · drag") {
                WaveformScrubber(peaks: DemoCatalog.rawWaveform(trackId: "demo"), progress: progress, duration: 214) { progress = $0 }
                ScrubTimes(progress: progress, duration: 214)
                WaveformScrubber(peaks: nil, progress: 0, duration: 214, height: 40) { _ in }
            }
        }
    }

    private func block<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).radarReadout()
            content()
        }
    }
}
#endif
