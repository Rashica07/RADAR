import SwiftUI

/// App entry point.
///
/// Targets: deployment **iOS 17.0**, developed and manually tested on **iOS 27**. Anything newer
/// than iOS 17 must be behind an availability check with a fallback (docs/PLATFORM_REQUIREMENTS.md).
///
/// All long-lived state lives here, above every layout, so nothing is lost when the window
/// changes shape (fold/unfold, Split View, Stage Manager, rotation).
@main
struct RadarApp: App {
    @State private var settings: SettingsStore
    @State private var library: LibraryStore
    @State private var downloads: DownloadCenter
    @State private var localLibrary: LocalLibrary
    @State private var toasts: ToastCenter
    @State private var flags: FeatureFlags
    @State private var icons: AppIconService
    @State private var probe = LabProbe()

    init() {
        let catalog = DemoCatalog.shared
        let toasts = ToastCenter()
        _settings = State(initialValue: SettingsStore())
        _library = State(initialValue: LibraryStore(catalog: catalog))
        _downloads = State(initialValue: DownloadCenter(catalog: catalog, toasts: toasts))
        _localLibrary = State(initialValue: LocalLibrary())
        _toasts = State(initialValue: toasts)
        _flags = State(initialValue: FeatureFlags())
        _icons = State(initialValue: AppIconService())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(library)
                .environment(downloads)
                .environment(localLibrary)
                .environment(toasts)
                .environment(flags)
                .environment(icons)
                .environment(probe)
                .preferredColorScheme(settings.settings.theme.colorScheme)
        }
    }
}
