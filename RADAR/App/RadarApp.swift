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
    @State private var player: PlayerStore
    private let nowPlaying: NowPlayingBridge

    init() {
        let catalog = DemoCatalog.shared
        let toasts = ToastCenter()
        _settings = State(initialValue: SettingsStore())
        _downloads = State(initialValue: DownloadCenter(catalog: catalog, toasts: toasts))
        _toasts = State(initialValue: toasts)
        _flags = State(initialValue: FeatureFlags())
        _icons = State(initialValue: AppIconService())

        let library = LibraryStore(catalog: catalog)
        let local = LocalLibrary()
        _library = State(initialValue: library)
        _localLibrary = State(initialValue: local)
        let store = PlayerStore(
            backend: AVPlayerBackend(),
            resolve: { catalog.track($0) ?? local.track($0) },
            localURL: { local.fileURL(for: $0) },
            onPlayed: { library.addRecent($0) })
        _player = State(initialValue: store)
        nowPlaying = NowPlayingBridge(store: store, artist: { catalog.artistName(for: $0) }, art: { catalog.art(for: $0) })
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
                .environment(player)
                .preferredColorScheme(settings.settings.theme.colorScheme)
        }
    }
}
