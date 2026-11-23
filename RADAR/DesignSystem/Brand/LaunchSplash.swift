import SwiftUI

/// The in-app launch moment: charcoal screen, the logo glitching into place, then a quick
/// fade into the app. The system launch screen is the same charcoal (`LaunchBackground`),
/// so there is no flash between the two.
struct LaunchSplash: View {
    /// False when Reduce Motion is on or "Signal effects" is off: the clean logo shows
    /// briefly with no glitch.
    var animated: Bool
    var onDone: () -> Void

    @State private var opacity = 1.0

    var body: some View {
        GeometryReader { geometry in
            let lockup = RadarBrandLayout.lockup
            let width = min(geometry.size.width * 0.78, 520)
            ZStack {
                Color("LaunchBackground").ignoresSafeArea()
                RadarLogoReveal(
                    layout: .lockup,
                    height: width * lockup.height / lockup.width,
                    animated: animated,
                    onFinished: finish
                )
            }
        }
        .opacity(opacity)
        .accessibilityHidden(true)
        .allowsHitTesting(opacity > 0.01)
    }

    private func finish() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(animated ? 0.35 : 0.6))
            withAnimation(.easeOut(duration: 0.3)) { opacity = 0 }
            try? await Task.sleep(for: .seconds(0.3))
            onDone()
        }
    }
}
