import Observation
import SwiftUI

/// The four top-level destinations. Settings is reached from a toolbar button, not a tab.
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case discover, trending, search, library
    var id: String { rawValue }

    var title: String {
        switch self {
        case .discover: "Discover"
        case .trending: "Trending"
        case .search: "Search"
        case .library: "Library"
        }
    }

    var icon: RadarIconName {
        switch self {
        case .discover: .discover
        case .trending: .trending
        case .search: .search
        case .library: .library
        }
    }

    var activeIcon: RadarIconName { self == .discover ? .discoverFill : icon }
}

/// Where a push can go. Detail pages join in Step 6.
enum AppRoute: Hashable {
    case settings
}

/// Selection and navigation paths. Lives at the app root, so a fold, Split View change or
/// rotation never loses where the user was.
@MainActor
@Observable
final class AppRouter {
    var selected: AppTab = .discover
    var paths: [AppTab: [AppRoute]] = [:]

    enum Select: Equatable { case switched, poppedToRoot, alreadyAtRoot }

    /// Tapping the active tab pops to its root, like every native tab bar.
    @discardableResult
    func select(_ tab: AppTab) -> Select {
        if tab == selected {
            guard !(paths[tab] ?? []).isEmpty else { return .alreadyAtRoot }
            paths[tab] = []
            return .poppedToRoot
        }
        selected = tab
        return .switched
    }

    func push(_ route: AppRoute, on tab: AppTab? = nil) {
        paths[tab ?? selected, default: []].append(route)
    }

    func path(for tab: AppTab) -> Binding<[AppRoute]> {
        Binding(get: { self.paths[tab] ?? [] }, set: { self.paths[tab] = $0 })
    }
}

/// What a drag on the mini player or the big artwork means. Pure, so it is unit-tested.
enum PlayerSwipe: Equatable {
    case expand, next, previous, none

    /// `translation` is where the finger is; `predicted` is where the flick would end.
    static func decide(translation: CGSize, predicted: CGSize) -> PlayerSwipe {
        let dx = predicted.width, dy = predicted.height
        if abs(translation.width) > abs(translation.height) || abs(dx) > abs(dy) * 1.5 {
            if dx < -70 { return .next }
            if dx > 70 { return .previous }
            return .none
        }
        return dy < -50 ? .expand : .none
    }
}

enum SheetDismiss {
    /// Pull-down on the expanded player: far enough, or flicked hard enough.
    static func shouldDismiss(translation: CGFloat, predicted: CGFloat, height: CGFloat) -> Bool {
        guard translation > 0 else { return false }
        return translation > height * 0.25 || (translation > 40 && predicted > height * 0.45)
    }

    /// Past the top edge, resist: the further you pull the less it follows.
    static func rubber(_ dy: CGFloat, limit: CGFloat = 80) -> CGFloat {
        guard dy < 0 else { return dy }
        let over = -dy
        return -(limit * over / (limit + over))
    }
}
