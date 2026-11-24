import SwiftUI

/// The four tabs. System `TabView` and `NavigationStack`s: the tab bar, back swipe, large titles,
/// sheets and search are all the platform's own. On iOS 26 and later the player lives in the tab
/// bar's bottom accessory; before that it sits above the bar.
struct MainTabs: View {
    @Environment(PlayerStore.self) private var player
    @Environment(ToastCenter.self) private var toasts
    @State private var selection = Tab.discover
    @State private var paths: [Tab: NavigationPath] = [:]
    @State private var topTicks: [Tab: Int] = [:]

    enum Tab: Hashable, CaseIterable {
        case discover, trending, search, library
        var title: String {
            switch self { case .discover: "Discover"; case .trending: "Trending"; case .search: "Search"; case .library: "Library" }
        }
        var symbol: String {
            switch self {
            case .discover: "dot.radiowaves.left.and.right"
            case .trending: "chart.line.uptrend.xyaxis"
            case .search: "magnifyingglass"
            case .library: "music.note.house"
            }
        }
    }

    var body: some View {
        ZStack {
            tabs
            if player.expanded { NowPlayingScreen().zIndex(5) }
        }
        .tint(Color.radarAccentText)
        .overlay(alignment: .top) { ToastBanner(center: toasts) }
        .animation(RadarUI.Motion.layer, value: player.expanded)
    }

    /// System `TabView` keeps each tab's scroll and stack alive; its bar is hidden and ours is used.
    private var tabs: some View {
        TabView(selection: $selection) {
            tabStack(.discover) { DiscoverScreen() }
            tabStack(.trending) { TrendingScreen() }
            tabStack(.search) { SearchScreen() }
            tabStack(.library) { LibraryScreen() }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                MiniPlayerBar()
                RadarTabBar(selection: $selection, title: \.title, symbol: \.symbol, onReselect: reselect)
            }
        }
    }
}

extension MainTabs {
    private func tabStack<Root: View>(_ tab: Tab, @ViewBuilder root: () -> Root) -> some View {
        NavigationStack(path: Binding(get: { paths[tab] ?? NavigationPath() }, set: { paths[tab] = $0 })) { root() }
            .background(ScrollToTopTrigger(tick: topTicks[tab] ?? 0))
            .toolbar(.hidden, for: .tabBar)
            .tag(tab)
    }

    /// Tapping the active tab: back out of a pushed screen first, otherwise scroll to the top.
    private func reselect(_ tab: Tab) {
        switch TabReselect.action(pushedCount: paths[tab]?.count ?? 0) {
        case .popToRoot: withAnimation(RadarUI.Motion.page) { paths[tab] = NavigationPath() }
        case .scrollToTop: topTicks[tab, default: 0] += 1
        }
    }
}

/// Short confirmation, in a system material.
struct ToastBanner: View {
    let center: ToastCenter
    var body: some View {
        if let toast = center.current {
            Label(toast.message, systemImage: toast.symbol ?? "info.circle")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.regularMaterial, in: .capsule)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onTapGesture { center.dismiss() }
                .accessibilityAddTraits(.updatesFrequently)
        }
    }
}
