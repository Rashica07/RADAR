import SwiftUI
import UIKit

/// What tapping the tab you are already on does: leave a pushed screen first, then go back to the top.
enum TabReselect {
    enum Action: Equatable { case popToRoot, scrollToTop }
    static func action(pushedCount: Int) -> Action { pushedCount > 0 ? .popToRoot : .scrollToTop }
}

/// Scrolls the visible list of the tab it sits behind to its top edge, animated.
/// SwiftUI has no scroll-to-top for a `List` before iOS 18, so this reaches the platform scroll view.
struct ScrollToTopTrigger: UIViewRepresentable {
    let tick: Int

    final class Coordinator { var last: Int; init(_ t: Int) { last = t } }
    func makeCoordinator() -> Coordinator { Coordinator(tick) }
    func makeUIView(context: Context) -> UIView { let v = UIView(); v.isUserInteractionEnabled = false; return v }

    func updateUIView(_ view: UIView, context: Context) {
        guard context.coordinator.last != tick else { return }
        context.coordinator.last = tick
        DispatchQueue.main.async {
            guard let scroll = Self.mainScrollView(near: view) else { return }
            scroll.setContentOffset(CGPoint(x: scroll.contentOffset.x, y: -scroll.adjustedContentInset.top), animated: true)
        }
    }

    /// Climb until a parent contains a vertical scroll view, then take the biggest one on screen.
    private static func mainScrollView(near view: UIView) -> UIScrollView? {
        var node: UIView? = view
        while let current = node {
            let found = scrollViews(in: current).filter { $0.window != nil && $0.bounds.width >= $0.bounds.height * 0.4 }
            if let best = found.max(by: { $0.bounds.height < $1.bounds.height }) { return best }
            node = current.superview
        }
        return nil
    }

    private static func scrollViews(in view: UIView) -> [UIScrollView] {
        var out: [UIScrollView] = []
        if let s = view as? UIScrollView, s.bounds.height > 200 { out.append(s) }
        for sub in view.subviews { out += scrollViews(in: sub) }
        return out
    }
}
