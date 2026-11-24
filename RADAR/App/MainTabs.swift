import SwiftUI

/// The four tabs. System `TabView` and `NavigationStack`s: the tab bar, back swipe, large titles,
/// sheets and search are all the platform's own. On iOS 26 and later the player lives in the tab
/// bar's bottom accessory; before that it sits above the bar.
struct MainTabs: View {
    @Environment(PlayerStore.self) private var player
    @Environment(ToastCenter.self) private var toasts
    @State private var selection = Tab.discover

    enum Tab: Hashable { case discover, trending, search, library }

    var body: some View {
        @Bindable var player = player
        tabs
            .tint(Color.radarAccentText)
            .overlay(alignment: .top) { ToastBanner(center: toasts) }
            .sheet(isPresented: $player.expanded) { NowPlayingSheet() }
    }

    @ViewBuilder
    private var tabs: some View {
        if #available(iOS 26.1, *) {
            tabView.tabViewBottomAccessory(isEnabled: player.current != nil) { MiniPlayerBar() }
        } else {
            tabView.modifier(LegacyPlayerInset())
        }
    }

    private var tabView: some View {
        TabView(selection: $selection) {
            NavigationStack { DiscoverScreen() }
                .tabItem { Label("Discover", systemImage: "dot.radiowaves.left.and.right") }.tag(Tab.discover)
            NavigationStack { TrendingScreen() }
                .tabItem { Label("Trending", systemImage: "chart.line.uptrend.xyaxis") }.tag(Tab.trending)
            NavigationStack { SearchScreen() }
                .tabItem { Label("Search", systemImage: "magnifyingglass") }.tag(Tab.search)
            NavigationStack { LibraryScreen() }
                .tabItem { Label("Library", systemImage: "music.note.house") }.tag(Tab.library)
        }
    }
}

/// Before iOS 26: the mini player is pinned above the tab bar.
private struct LegacyPlayerInset: ViewModifier {
    @Environment(PlayerStore.self) private var player
    func body(content: Content) -> some View {
        content
        .overlay(alignment: .bottom) {
            if player.current != nil {
                MiniPlayerBar().frame(height: 52).background(.bar).overlay(alignment: .top) { Divider() }
                    .padding(.bottom, 49)
            }
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
