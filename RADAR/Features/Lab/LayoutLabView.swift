import Observation
import SwiftUI

/// Store-held probe: survives every layout change because it lives above the layout.
@MainActor
@Observable
final class LabProbe {
    var count = 0
}

/// TEMPORARY developer screen (replaced by the real app in Phase 3; keep it behind `#if DEBUG`
/// in release builds).
///
/// What it is for, on iOS 27 simulators and devices:
/// 1. **Calibration** — read the *actual* point size, safe area and size classes of each display
///    (Apple publishes pixel sizes for iPhone Duo but no point sizes) and watch them change live.
/// 2. **Layout profile** — see which navigation style / columns / player / dock RADAR picks.
/// 3. **State preservation** — three counters; fold, unfold, resize, rotate and see which survive.
/// 4. **Availability** — which OS release is actually running (Duo-specific APIs need iOS 27.1).
struct LayoutLabView: View {
    @Environment(\.radarLayout) private var layout
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.displayScale) private var displayScale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(LabProbe.self) private var probe
    @Environment(SettingsStore.self) private var settings

    @State private var stableTaps = 0
    @State private var sizeLog: [SizeLogEntry] = []
    @State private var replay = 0

    private struct SizeLogEntry: Identifiable {
        let id = UUID()
        let time: Date
        let text: String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                header
                container
                profile
                stateProbes
                availability
                brand
                #if DEBUG
                debugControls
                #endif
            }
            .padding(.horizontal, RadarLayoutProfile.gutter)
            .padding(.vertical, 24)
            .frame(maxWidth: layout.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color.radarBg)
        .onAppear { record(layout.size) }
        .onChange(of: layout.size) { _, newSize in record(newSize) }
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Layout lab").radarReadout(Color.radarSignalText)
            Text("Fold, unfold, rotate or resize the window")
                .font(RadarFont.display(40, .black))
                .textCase(.uppercase)
                .foregroundStyle(Color.radarText)
                .fixedSize(horizontal: false, vertical: true)
            Text("Temporary developer screen. Numbers below are measured live from the window, never from the device model.")
                .font(RadarFont.body(14))
                .foregroundStyle(Color.radarText2)
        }
    }

    private var container: some View {
        section("Container (measured)") {
            row("Window size", "\(fmt(layout.size.width)) × \(fmt(layout.size.height)) pt")
            row("Shape", layout.isLandscapeShaped ? "wider than tall" : "taller than wide")
            row("Aspect (w/h)", layout.size.height > 0 ? String(format: "%.3f", layout.size.width / layout.size.height) : "—")
            row("Safe area (t/l/b/r)", "\(fmt(layout.safeArea.top)) / \(fmt(layout.safeArea.leading)) / \(fmt(layout.safeArea.bottom)) / \(fmt(layout.safeArea.trailing))")
            row("Size classes (h/v)", "\(name(horizontalSizeClass)) / \(name(verticalSizeClass))")
            row("Display scale", "\(fmt(displayScale))×")
            row("Dynamic Type", String(describing: dynamicTypeSize))
            Text("Size changes (newest first)").radarReadout().padding(.top, 8)
            if sizeLog.isEmpty {
                Text("none yet").font(RadarFont.body(13)).foregroundStyle(Color.radarText3)
            } else {
                ForEach(sizeLog.prefix(8)) { entry in
                    Text("\(entry.time.formatted(date: .omitted, time: .standard))  \(entry.text)")
                        .font(RadarFont.body(13))
                        .monospacedDigit()
                        .foregroundStyle(Color.radarText2)
                }
            }
        }
    }

    private var profile: some View {
        section("RADAR layout profile (derived)") {
            row("Navigation", layout.navigation.rawValue)
            row("Player chrome", layout.playerChrome.rawValue)
            row("Two-column pages", yesNo(layout.usesTwoColumnPages))
            row("Two-pane player", yesNo(layout.usesTwoPanePlayer))
            row("Queue dock available", yesNo(layout.supportsQueueDock))
            row("Queue dock open by default", yesNo(layout.queueDockOpensByDefault))
            row("Cover-grid columns", "\(layout.gridColumns)")
            row("Content max width", "\(fmt(layout.contentMaxWidth)) pt")
            Text("Breakpoints (pt): rail \(fmt(RadarBreakpoint.rail)) · player \(fmt(RadarBreakpoint.twoPanePlayer)) · columns \(fmt(RadarBreakpoint.twoColumn)) · sidebar \(fmt(RadarBreakpoint.sidebar)) · dock \(fmt(RadarBreakpoint.dock)) · dock open \(fmt(RadarBreakpoint.dockOpensByDefault)). From the approved artifact; wide-shaped containers also get the two-column pages/player earlier (an assumption).")
                .font(RadarFont.body(12))
                .foregroundStyle(Color.radarText3)
        }
    }

    private var stateProbes: some View {
        section("State preservation probes") {
            Text("Tap each one a few times, then fold/unfold, rotate or resize. Record which counters survive.")
                .font(RadarFont.body(13))
                .foregroundStyle(Color.radarText2)
            probeRow("A · Store-held counter (should always survive)", value: probe.count) { probe.count += 1 }
            probeRow("B · @State at a stable position (should survive)", value: stableTaps) { stableTaps += 1 }
            // C deliberately sits in two *different* branches, so SwiftUI gives it a new identity
            // whenever the condition flips. It is expected to RESET — this is the pitfall.
            if layout.isLandscapeShaped {
                BranchProbe(title: "C · @State inside a layout branch (EXPECTED TO RESET when the window changes shape)")
            } else {
                BranchProbe(title: "C · @State inside a layout branch (EXPECTED TO RESET when the window changes shape)")
            }
        }
    }

    private var availability: some View {
        section("Runtime availability") {
            row("OS", ProcessInfo.processInfo.operatingSystemVersionString)
            row("≥ 17.0 (deployment floor)", yesNo(atLeast(17, 0)))
            row("≥ 18.0", yesNo(atLeast(18, 0)))
            row("≥ 26.0", yesNo(atLeast(26, 0)))
            row("≥ 27.0", yesNo(atLeast(27, 0)))
            row("≥ 27.1 (Duo layout APIs)", yesNo(atLeast(27, 1)))
            Text("ArrangementView, reservedRegions and toolbarVerticalEdge are documented as iOS 27.1+. They are not used yet; when adopted they will be gated, with the container-based layout above as the iOS 17–27.0 fallback.")
                .font(RadarFont.body(12))
                .foregroundStyle(Color.radarText3)
        }
    }

    private var brand: some View {
        section("Brand") {
            RadarLogoReveal(
                layout: .lockup,
                height: 56,
                animated: settings.settings.fx,
                replay: replay
            )
            Button("Replay logo reveal") { replay += 1 }
                .font(RadarFont.ui(13, .bold))
                .foregroundStyle(Color.radarAccentText)
        }
    }

    #if DEBUG
    /// Design-review controls (icon picker + local flag overrides). Compiled out of release builds so
    /// no user can unlock a flagged feature locally.
    private var debugControls: some View {
        VStack(alignment: .leading, spacing: 30) {
            AppIconPickerSection()
            section("Feature flags (design review)") {
                FeatureFlagControls()
            }
        }
    }
    #endif

    // MARK: Helpers

    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).radarReadout()
            content()
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(RadarFont.ui(14, .medium))
                .foregroundStyle(Color.radarText2)
            Spacer(minLength: 12)
            Text(value)
                .font(RadarFont.ui(14, .semibold))
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Color.radarText)
        }
    }

    private func probeRow(_ title: String, value: Int, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(RadarFont.ui(14, .medium))
                .foregroundStyle(Color.radarText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 12)
            Button("\(value)", action: action)
                .font(RadarFont.display(28, .black))
                .foregroundStyle(Color.radarOnAccent)
                .frame(minWidth: 56, minHeight: 44)
                .background(Color.radarAccent)
        }
    }

    private func record(_ size: CGSize) {
        let text = "\(fmt(size.width)) × \(fmt(size.height)) pt · nav \(RadarLayoutProfile.make(for: size).navigation.rawValue)"
        if sizeLog.first?.text == text { return }
        sizeLog.insert(SizeLogEntry(time: .now, text: text), at: 0)
        if sizeLog.count > 20 { sizeLog.removeLast(sizeLog.count - 20) }
    }

    private func fmt(_ value: CGFloat) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
    }

    private func name(_ sizeClass: UserInterfaceSizeClass?) -> String {
        switch sizeClass {
        case .compact: "compact"
        case .regular: "regular"
        case nil: "nil"
        @unknown default: "?"
        }
    }

    private func yesNo(_ value: Bool) -> String { value ? "yes" : "no" }

    /// Runtime check (not a compile-time availability check): used only to *display* the OS release.
    private func atLeast(_ major: Int, _ minor: Int) -> Bool {
        ProcessInfo.processInfo.isOperatingSystemAtLeast(
            OperatingSystemVersion(majorVersion: major, minorVersion: minor, patchVersion: 0)
        )
    }
}

/// Holds its own `@State`, to demonstrate that state inside a swapped layout branch is lost.
private struct BranchProbe: View {
    let title: String
    @State private var taps = 0

    var body: some View {
        HStack {
            Text(title)
                .font(RadarFont.ui(14, .medium))
                .foregroundStyle(Color.radarSignalText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 12)
            Button("\(taps)") { taps += 1 }
                .font(RadarFont.display(28, .black))
                .foregroundStyle(Color.radarOnSignal)
                .frame(minWidth: 56, minHeight: 44)
                .background(Color.radarSignal)
        }
    }
}
