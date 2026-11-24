import SwiftUI

/// Home: what's new, what's climbing, and ways in by genre.
struct DiscoverScreen: View {
    @Environment(SettingsStore.self) private var settings
    @State private var showSettings = false

    var body: some View {
        let catalog = DemoCatalog.shared
        let country = settings.settings.country
        let chart = catalog.chart(country: country, window: .week, limit: 10)
        let ids = chart.map(\.track.id)
        let releases = catalog.newReleases(limit: 10)
        List {
            Section {
                Text("Find what's moving")
                    .font(RadarFont.display(40, .black)).textCase(.uppercase)
                    .listRowBackground(Color.clear).listRowSeparator(.hidden)
                    .accessibilityAddTraits(.isHeader)
            }
            Section("New releases") {
                Rail { ForEach(releases) { t in
                    ReleaseTile(track: t, context: releases.map(\.id))
                } }
            }
            Section {
                ForEach(chart) { e in
                    TrackRowView(track: e.track, context: ids, rank: e.rank, delta: e.delta)
                }
            } header: {
                Text("Top in \(catalog.countryName(country))")
            }
            Section("Rising artists") {
                Rail { ForEach(catalog.risingArtists(limit: 10)) { a in
                    NavigationLink(value: Route.artist(a.id)) {
                        CoverTile(art: catalog.art(for: a), title: a.name, subtitle: "\(Format.compact(a.listeners)) listeners")
                    }.buttonStyle(.plain)
                } }
            }
            Section("Genres") {
                Rail { ForEach(catalog.genres) { g in
                    NavigationLink(value: Route.genre(g.id)) {
                        CoverTile(art: catalog.art(for: g), title: g.name)
                    }.buttonStyle(.plain)
                } }
            }
            Section("Playlists") {
                Rail { ForEach(catalog.editorialPlaylists) { p in
                    NavigationLink(value: Route.playlist(p.id)) {
                        CoverTile(art: catalog.art(forPlaylistSeed: p.seed), title: p.title, subtitle: p.curator)
                    }.buttonStyle(.plain)
                } }
            }
        }
        .radarListBackground()
        .navigationTitle("Discover")
        .toolbar { SettingsButton(show: $showSettings) }
        .settingsSheet($showSettings)
        .radarDestinations()
    }
}

private struct ReleaseTile: View {
    let track: Track
    let context: [String]
    @Environment(PlayerStore.self) private var player

    var body: some View {
        Button { player.play(track.id, in: context) } label: {
            CoverTile(art: DemoCatalog.shared.art(for: track), title: track.title,
                      subtitle: DemoCatalog.shared.artistName(for: track))
        }
        .buttonStyle(.plain)
    }
}

/// A horizontal row of tiles inside a list section.
struct Rail<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 14) { content }
                .scrollTargetLayout()
                .padding(.horizontal, 16).padding(.vertical, 6)
        }
        .scrollTargetBehavior(.viewAligned)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}

/// Chart by window. Country comes from Settings.
struct TrendingScreen: View {
    @Environment(SettingsStore.self) private var settings
    @State private var window = ChartWindow.week

    var body: some View {
        let catalog = DemoCatalog.shared
        let country = settings.settings.country
        let chart = catalog.chart(country: country, window: window, limit: 30)
        let ids = chart.map(\.track.id)
        List {
            Section {
                Picker("Window", selection: $window) {
                    ForEach(ChartWindow.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            } footer: {
                Text("\(catalog.countryName(country)) · demo chart, not real listening data")
            }
            Section {
                ForEach(chart) { e in
                    TrackRowView(track: e.track, context: ids, rank: e.rank, delta: e.isNew ? 0 : e.delta)
                }
            }
        }
        .radarListBackground()
        .navigationTitle("Trending")
        .radarDestinations()
    }
}
