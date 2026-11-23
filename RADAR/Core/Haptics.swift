import UIKit

/// RADAR's haptic vocabulary. The names and their iOS generators come straight from
/// the Phase 01 design tokens (`$haptic` in tokens.json).
enum Haptic {
    case tick, select, light, medium, success, warning
}

@MainActor
enum Haptics {
    /// Mirrors the "Haptic feedback" setting. Updated by `SettingsStore`.
    static var isEnabled = true

    private static let selection = UISelectionFeedbackGenerator()
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let notification = UINotificationFeedbackGenerator()

    static func play(_ haptic: Haptic) {
        guard isEnabled else { return }
        switch haptic {
        case .tick: selection.selectionChanged()
        case .select, .light: lightImpact.impactOccurred()
        case .medium: mediumImpact.impactOccurred()
        case .success: notification.notificationOccurred(.success)
        case .warning: notification.notificationOccurred(.warning)
        }
    }
}
