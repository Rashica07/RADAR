import Foundation
import Observation

/// Short confirmations ("Saved to Library", "Will play next"). One at a time, 2.4 s each.
@MainActor
@Observable
final class ToastCenter {
    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let message: String
        let icon: RadarIconName?
    }

    private(set) var current: Toast?
    private var dismissTask: Task<Void, Never>?

    func show(_ message: String, icon: RadarIconName? = nil) {
        dismissTask?.cancel()
        let toast = Toast(message: message, icon: icon)
        current = toast
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.4))
            guard !Task.isCancelled else { return }
            if self?.current?.id == toast.id { self?.current = nil }
        }
    }
}
