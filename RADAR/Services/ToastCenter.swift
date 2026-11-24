import Foundation
import Observation

/// Short confirmations ("Saved to Library", "Will play next"). One at a time, 2.4 s each.
@MainActor
@Observable
final class ToastCenter {
    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let message: String
        let symbol: String?
    }

    private(set) var current: Toast?
    private var dismissTask: Task<Void, Never>?
    private let duration: Duration

    init(duration: Duration = .seconds(2.4)) { self.duration = duration }

    /// Hides the toast now (swipe-away, or a screen change).
    func dismiss() {
        dismissTask?.cancel()
        current = nil
    }

    func show(_ message: String, symbol: String? = nil) {
        dismissTask?.cancel()
        let toast = Toast(message: message, symbol: symbol)
        current = toast
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: self?.duration ?? .seconds(2.4))
            guard !Task.isCancelled else { return }
            if self?.current?.id == toast.id { self?.current = nil }
        }
    }
}
