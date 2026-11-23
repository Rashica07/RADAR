import SwiftUI
import Observation

enum ThemePreference: String, Codable, CaseIterable, Sendable {
    case dark, light, system

    var label: String {
        switch self {
        case .dark: "Dark"
        case .light: "Paper"
        case .system: "System"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .dark: .dark
        case .light: .light
        case .system: nil
        }
    }
}

enum RowDensity: String, Codable, CaseIterable, Sendable {
    case comfortable, compact

    var label: String { rawValue.capitalized }
    var rowHeight: CGFloat { self == .compact ? 52 : 60 }
    var artSize: CGFloat { self == .compact ? 42 : 52 }
}

struct Settings: Codable, Equatable, Sendable {
    var theme: ThemePreference = .dark
    var density: RowDensity = .comfortable
    /// True when the user turned on "Reduce motion" inside RADAR (the system setting is honoured separately).
    var reduceMotion = false
    var country = "IT"
    var genres: [String] = ["Afrobeats", "Alt R&B", "House"]
    var hideExplicit = false
    var fx = true
    var haptics = true
}

/// Appearance and discovery preferences. Persisted locally.
@MainActor
@Observable
final class SettingsStore {
    private static let key = "settings"
    private let persistence: PersistenceController

    var settings: Settings {
        didSet {
            guard settings != oldValue else { return }
            Haptics.isEnabled = settings.haptics
            persistence.save(settings, key: Self.key)
        }
    }

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        let stored = persistence.load(Settings.self, key: Self.key) ?? Settings()
        self.settings = stored
        Haptics.isEnabled = stored.haptics
    }

    func toggleGenre(_ name: String) {
        if let i = settings.genres.firstIndex(of: name) {
            settings.genres.remove(at: i)
        } else {
            settings.genres.append(name)
        }
    }

    func reset() {
        settings = Settings()
    }
}
