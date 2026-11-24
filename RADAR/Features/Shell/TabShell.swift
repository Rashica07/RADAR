import SwiftUI

/// The app frame: navigation (bottom bar, rail or sidebar), one `NavigationStack` per tab, the
/// player chrome (mini player or transport bar), the queue dock, and the expanded player.
///
/// Tab content sits in a `TabView` with its own bar hidden: SwiftUI keeps each tab's scroll
/// position and stack alive while it is off screen, and the bar itself is ours.
struct TabShell: View {
    @Environment(\.radarLayout) private var layout
    @Environment(AppRouter.self) private var router
    @Environment(PlayerStore.self) private var player
    @Environment(ToastCenter.self) private var toasts
    @Namespace private var art

    var body: some View {
        @Bindable var router = router
        ZStack {
            HStack(spacing: 0) {
                if layout.navigation != .bottomBar { SideNav(showsLabels: layout.navigation == .sidebar) }
                VStack(spacing: 0) {
                    TabView(selection: $router.selected) {
                        ForEach(AppTab.allCases) { tab in
                            TabRoot(tab: tab)
                                .toolbar(.hidden, for: .tabBar)
                                .tag(tab)
                        }
                    }
                    if layout.playerChrome == .transportBar { TransportBar(art: art) }
                }
                if layout.supportsQueueDock && player.dockOpen && layout.playerChrome == .transportBar {
                    QueueList().frame(width: 340)
                        .overlay(alignment: .leading) { Rectangle().fill(Color.radarLine).frame(width: 1) }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if layout.navigation == .bottomBar {
                    VStack(spacing: 0) {
                        if layout.playerChrome == .miniPlayer { MiniPlayer(art: art) }
                        BottomNav()
                    }
                }
            }
            .animation(.snappy, value: player.current?.id == nil)
            .animation(.snappy, value: player.dockOpen)

            if player.expanded {
                ExpandedPlayer(art: art).zIndex(5)
            }
        }
        .background(Color.radarBg.ignoresSafeArea())
        .toastHost(toasts, bottomInset: layout.navigation == .bottomBar ? (player.current == nil ? 64 : 140) : 80)
    }
}

/// One tab: its own stack, its own path. The pages are stand-ins until the Step 6 screens land.
private struct TabRoot: View {
    let tab: AppTab
    @Environment(AppRouter.self) private var router

    var body: some View {
        NavigationStack(path: router.path(for: tab)) {
            TabPlaceholderPage(tab: tab)
                .navigationTitle(tab.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { router.push(.settings, on: tab) } label: { RadarIcon(.settings, size: 22) }
                            .accessibilityLabel("Settings")
                    }
                }
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .settings: SettingsPlaceholder()
                    }
                }
        }
        .tint(Color.radarAccentText)
    }
}

/// Stand-in content so the shell can be used end to end: a playable list per tab.
private struct TabPlaceholderPage: View {
    let tab: AppTab
    @Environment(PlayerStore.self) private var player
    @Environment(LibraryStore.self) private var library

    var body: some View {
        let catalog = DemoCatalog.shared
        let entries = catalog.chart(country: "GLOBAL", window: .week, limit: tab == .trending ? 20 : 10)
        let ids = entries.map(\.track.id)
        List {
            SectionHeader(tab.title, idx: String(format: "%02d", (AppTab.allCases.firstIndex(of: tab) ?? 0) + 1),
                          kicker: "Shell preview", sub: "The real \(tab.title) screen arrives in the next step.")
                .listRowBackground(Color.clear).listRowInsets(EdgeInsets(top: 8, leading: RadarScale.gutter, bottom: 8, trailing: RadarScale.gutter))
            ForEach(entries) { entry in
                let t = entry.track
                let current = player.current?.id == t.id
                let model = TrackRowModel(track: t, artist: catalog.artistName(for: t), entry: entry, isCurrent: current,
                                          isPlaying: current && player.isPlaying, isSaved: library.isSaved(t.id))
                let art = catalog.art(for: t)
                let actions = TrackRowActions(play: { player.play(t.id, in: ids) }, toggleSave: { _ = library.toggleSave(t.id) },
                                              addToPlaylist: {}, openDetails: {})
                TrackRow(model: model, art: art, actions: actions)
                    .trackActions(model, art: art, actions)
                    .listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.radarBg)
    }
}

private struct SettingsPlaceholder: View {
    var body: some View {
        #if DEBUG
        LayoutLabView().navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
        #else
        Text("Settings").navigationTitle("Settings")
        #endif
    }
}
