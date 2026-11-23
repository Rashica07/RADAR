import Observation
import UIKit

/// The app icons RADAR can show on the Home Screen.
///
/// Alternate icons must be compiled into the app (asset sets named below, listed in the
/// `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` build setting). A remote flag can only
/// decide whether the *picker* is offered, never deliver a new icon after release.
enum AppIconChoice: String, CaseIterable, Identifiable, Sendable {
    case standard
    case glitch

    var id: String { rawValue }

    /// Asset-catalog name passed to iOS. Nil selects the primary icon (`AppIcon`).
    var alternateName: String? {
        switch self {
        case .standard: nil
        case .glitch: "AppIconGlitch"
        }
    }

    var title: String {
        switch self {
        case .standard: "RADAR"
        case .glitch: "Glitch"
        }
    }

    var subtitle: String {
        switch self {
        case .standard: "Mint & coral"
        case .glitch: "Signal breaking up"
        }
    }

    /// Preview image in the asset catalog (alternate icon sets can't be loaded by name).
    var previewAsset: String {
        switch self {
        case .standard: "IconPreviewDefault"
        case .glitch: "IconPreviewGlitch"
        }
    }

    /// The flag that must be on before this icon is offered. Nil = always offered.
    var requiredFlag: FeatureFlag? {
        switch self {
        case .standard: nil
        case .glitch: .glitchAppIcon
        }
    }

    init(alternateName: String?) {
        self = Self.allCases.first { $0.alternateName == alternateName } ?? .standard
    }
}

/// The slice of `UIApplication` the service needs, so it can be tested.
@MainActor
protocol AppIconApplying {
    var supportsAlternateIcons: Bool { get }
    var alternateIconName: String? { get }
    func setAlternateIconName(_ name: String?) async throws
}

@MainActor
struct SystemIconApplier: AppIconApplying {
    var supportsAlternateIcons: Bool { UIApplication.shared.supportsAlternateIcons }
    var alternateIconName: String? { UIApplication.shared.alternateIconName }

    func setAlternateIconName(_ name: String?) async throws {
        try await UIApplication.shared.setAlternateIconName(name)
    }
}

/// Reads and changes the Home Screen icon.
///
/// iOS owns the choice: it persists across launches and updates, and the user can change
/// it again at any time. iOS shows its own "You have changed the icon" confirmation; apps
/// can't suppress it.
@MainActor
@Observable
final class AppIconService {
    private let applier: AppIconApplying
    private(set) var current: AppIconChoice

    /// `applier` is optional (not a default argument) because a default argument is evaluated
    /// outside the main actor, and `SystemIconApplier` is main-actor isolated.
    init(applier: AppIconApplying? = nil) {
        let applier = applier ?? SystemIconApplier()
        self.applier = applier
        current = AppIconChoice(alternateName: applier.alternateIconName)
    }

    var supportsAlternateIcons: Bool { applier.supportsAlternateIcons }

    /// Re-reads the system value (it can change outside the app, e.g. through Shortcuts).
    func refresh() {
        current = AppIconChoice(alternateName: applier.alternateIconName)
    }

    /// Icons to show in Settings. An icon whose flag is off stays listed while it is the
    /// active one, so nobody gets stuck on an icon with no way back to the standard one.
    func availableChoices(flags: FeatureFlags) -> [AppIconChoice] {
        AppIconChoice.allCases.filter { choice in
            guard let flag = choice.requiredFlag else { return true }
            return flags.isEnabled(flag) || choice == current
        }
    }

    /// The picker only appears when there is a real choice to make.
    func isPickerVisible(flags: FeatureFlags) -> Bool {
        supportsAlternateIcons && availableChoices(flags: flags).count > 1
    }

    func select(_ choice: AppIconChoice) async throws {
        guard choice != current else { return }
        try await applier.setAlternateIconName(choice.alternateName)
        current = choice
    }
}
