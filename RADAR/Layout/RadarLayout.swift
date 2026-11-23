import SwiftUI

/// Container-based layout decisions for RADAR.
///
/// **Rule:** layout is chosen from the size of the space the UI actually has — never from
/// the device model, `userInterfaceIdiom`, `UIScreen`, or the device orientation. Apple's
/// guidance for iPhone Duo is explicit that "regular width" no longer means iPad and that an
/// iPhone app can see any combination of size classes. A window can also change size mid
/// session (fold/unfold, Split View, Stage Manager, resizable simulator, iPhone Mirroring).
///
/// Everything in this file uses only APIs available on **iOS 17.0**.
///
/// ## Breakpoints
/// The widths below are not invented: they are the media-query breakpoints of the approved
/// Phase 01 artifact (CSS px == points), so the native layouts follow the approved design.
enum RadarBreakpoint {
    /// Bottom navigation becomes a 76 pt side rail.
    static let rail: CGFloat = 720
    /// Full-screen player becomes two columns (art | queue).
    static let twoPanePlayer: CGFloat = 900
    /// Multi-column pages (Discover hero split, Trending, Search, Settings, Library rows).
    static let twoColumn: CGFloat = 1000
    /// The rail grows into a 244 pt sidebar with playlists.
    static let sidebar: CGFloat = 1100
    /// A 348 pt queue dock *can* be opened beside the content (a toggle in the transport bar).
    static let dock: CGFloat = 1280
    /// The dock is *open by default* only at this width (artifact: `innerWidth >= 1680`).
    static let dockOpensByDefault: CGFloat = 1680

    // ---- `[ASSUMPTION]` Not in the artifact — a DESIGN GAP this file fills --------------------
    // The artifact defines single-column pages from 720–999 pt and splits only at 1000+. A
    // *short, wide* container (an open iPhone Duo, an iPhone in landscape) falls in that band
    // and would show one huge column: that is "scaling up the closed interface". Containers
    // clearly wider than tall therefore get the two-column pages and the two-pane player
    // earlier. Needs design approval and judgement on a real device.
    /// width / height above which a container counts as "wide-shaped".
    static let wideShapeAspect: CGFloat = 1.15
    /// Minimum width for the two-pane player in a wide-shaped container.
    static let wideShapePlayerMinWidth: CGFloat = 640
}

enum RadarNavigationStyle: String, Equatable {
    /// Compact containers: bottom navigation (artifact `.bottom-nav`).
    case bottomBar
    /// Medium containers: 76 pt icon rail (artifact `.side-nav` ≥ 720).
    case rail
    /// Large containers: 244 pt sidebar with wordmark and playlists (artifact ≥ 1100).
    case sidebar
}

/// What carries playback controls (artifact: the mini-player and bottom nav are replaced by an
/// 88 pt full-width transport bar at ≥ 720 pt).
enum RadarPlayerChrome: String, Equatable {
    /// Compact containers: a mini-player docked above the bottom nav.
    case miniPlayer
    /// Medium and large containers: a persistent full-width transport bar.
    case transportBar
}

/// Everything a screen needs to know about the space it has. Pure value, derived from the
/// container size only, so it is trivially unit-testable.
struct RadarLayoutProfile: Equatable {
    var size: CGSize
    var safeArea: EdgeInsets
    var navigation: RadarNavigationStyle
    var playerChrome: RadarPlayerChrome
    var usesTwoColumnPages: Bool
    var usesTwoPanePlayer: Bool
    /// The queue dock can be toggled open (a persistent expanded queue beside the content).
    var supportsQueueDock: Bool
    /// The dock starts open (very wide windows only).
    var queueDockOpensByDefault: Bool
    /// Cover-grid columns. Always even (2 or 4): Apple recommends even column counts so a
    /// grid divides cleanly across the fold of a partially folded iPhone Duo.
    /// (The artifact used 2 / 3 / 4.)
    var gridColumns: Int
    var contentMaxWidth: CGFloat

    static let gutter: CGFloat = 16
    /// Artifact `.page { max-width: 1360px }` — keeps wide windows from stretching content.
    static let maxContentWidth: CGFloat = 1360

    var isLandscapeShaped: Bool { size.width > size.height }

    static func make(for size: CGSize, safeArea: EdgeInsets = EdgeInsets()) -> RadarLayoutProfile {
        let w = size.width
        let h = size.height
        let navigation: RadarNavigationStyle =
            w >= RadarBreakpoint.sidebar ? .sidebar : (w >= RadarBreakpoint.rail ? .rail : .bottomBar)
        let wideShape = w > h * RadarBreakpoint.wideShapeAspect
        return RadarLayoutProfile(
            size: size,
            safeArea: safeArea,
            navigation: navigation,
            playerChrome: w >= RadarBreakpoint.rail ? .transportBar : .miniPlayer,
            usesTwoColumnPages: w >= RadarBreakpoint.twoColumn || (w >= RadarBreakpoint.rail && wideShape),
            usesTwoPanePlayer: w >= RadarBreakpoint.twoPanePlayer
                || (w >= RadarBreakpoint.wideShapePlayerMinWidth && wideShape),
            supportsQueueDock: w >= RadarBreakpoint.dock,
            queueDockOpensByDefault: w >= RadarBreakpoint.dockOpensByDefault,
            gridColumns: w >= RadarBreakpoint.rail ? 4 : 2,
            contentMaxWidth: maxContentWidth
        )
    }
}

private struct RadarLayoutKey: EnvironmentKey {
    /// Neutral placeholder (zero size → compact). Real values come from `RadarAdaptiveContainer`.
    static let defaultValue = RadarLayoutProfile.make(for: .zero)
}

extension EnvironmentValues {
    var radarLayout: RadarLayoutProfile {
        get { self[RadarLayoutKey.self] }
        set { self[RadarLayoutKey.self] = newValue }
    }
}

/// Measures the space it is given (not the screen) and publishes a `RadarLayoutProfile`.
/// It re-evaluates on every size change, so a fold, an iPad window resize or a Split View
/// change re-lays out live. Put it once, near the root of each window.
///
/// - Important: **State must not live in views that this container swaps.** When the
///   profile changes, branches such as `if profile.navigation == .rail { … } else { … }`
///   create different view identities and any `@State` inside them is lost. Keep navigation
///   paths, scroll anchors, the queue and playback in app-level `@Observable` stores, and
///   keep page content at a stable structural position.
struct RadarAdaptiveContainer<Content: View>: View {
    private let content: (RadarLayoutProfile) -> Content

    init(@ViewBuilder content: @escaping (RadarLayoutProfile) -> Content) {
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            let profile = RadarLayoutProfile.make(for: proxy.size, safeArea: proxy.safeAreaInsets)
            content(profile)
                .environment(\.radarLayout, profile)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
