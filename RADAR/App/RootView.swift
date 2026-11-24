import SwiftUI

/// Window root: the tabs, with the launch splash on top.
struct RootView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(FeatureFlags.self) private var flags
    @Environment(AppIconService.self) private var icons
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var showSplash = true

    var body: some View {
        ZStack {
            Color.radarBg.ignoresSafeArea()

            MainTabs()

            if showSplash {
                LaunchSplash(animated: settings.settings.fx && !reduceMotion) {
                    showSplash = false
                }
                .ignoresSafeArea()
                .zIndex(10)
            }
        }
        .task { await flags.refresh() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                icons.refresh()
                Task { await flags.refresh() }
            case .background:
                PersistenceController.shared.flush()
            default:
                break
            }
        }
    }
}
