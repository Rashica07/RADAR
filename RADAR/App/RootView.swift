import SwiftUI

/// Window root: adaptive container → (temporary) Layout Lab, with the launch splash on top.
///
/// The Lab stands in for the real screens until Phase 3. It exists so a first run on iOS 27 can
/// report real point sizes for every display and prove layout/state behaviour across resizes.
struct RootView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(FeatureFlags.self) private var flags
    @Environment(AppIconService.self) private var icons
    @Environment(ToastCenter.self) private var toasts
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var showSplash = true

    var body: some View {
        ZStack {
            Color.radarBg.ignoresSafeArea()

            RadarAdaptiveContainer { _ in
                LayoutLabView()
            }

            if showSplash {
                LaunchSplash(animated: settings.settings.fx && !reduceMotion) {
                    showSplash = false
                }
                .ignoresSafeArea()
                .zIndex(10)
            }
        }
        .overlay(alignment: .bottom) { toastOverlay }
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

    /// Minimal stand-in for the real toast host (Phase 3).
    @ViewBuilder
    private var toastOverlay: some View {
        if let toast = toasts.current {
            Text(toast.message)
                .font(RadarFont.ui(13, .bold))
                .foregroundStyle(Color.radarBg)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.radarText)
                .padding(.bottom, 24)
                .transition(.opacity)
                .allowsHitTesting(false)
        }
    }
}
