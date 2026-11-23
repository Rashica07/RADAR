import SwiftUI

/// "App icon" group in Settings. Appears only when a choice exists beyond the standard
/// icon: the Glitch icon's flag is on, or it is the icon currently in use.
struct AppIconPickerSection: View {
    @Environment(AppIconService.self) private var icons
    @Environment(FeatureFlags.self) private var flags
    @Environment(ToastCenter.self) private var toasts

    @State private var isChanging = false

    var body: some View {
        if icons.isPickerVisible(flags: flags) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Home Screen")
                    .radarReadout()
                Text("App icon")
                    .font(RadarFont.display(44, .black))
                    .textCase(.uppercase)
                    .foregroundStyle(Color.radarText)
                    .accessibilityAddTraits(.isHeader)

                HStack(alignment: .top, spacing: 14) {
                    ForEach(icons.availableChoices(flags: flags)) { choice in
                        tile(choice)
                    }
                }

                Text(footnote)
                    .font(RadarFont.body(13))
                    .foregroundStyle(Color.radarText2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear { icons.refresh() }
        }
    }

    private var footnote: String {
        if icons.current == .glitch, !flags.isEnabled(.glitchAppIcon) {
            return "Glitch isn't offered as a new choice anymore. You can keep it, or switch back to the standard icon any time."
        }
        return "iOS asks you to confirm the change. Switch back to the standard icon any time."
    }

    private func tile(_ choice: AppIconChoice) -> some View {
        let selected = icons.current == choice
        let size: CGFloat = 92
        let corner = size * 0.2237
        return Button {
            select(choice)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(choice.previewAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .strokeBorder(selected ? Color.radarAccent : Color.radarLineStrong, lineWidth: selected ? 3 : 1)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        if selected {
                            RadarIcon(.check, size: 14)
                                .foregroundStyle(Color.radarOnAccent)
                                .frame(width: 24, height: 24)
                                .background(Color.radarAccent, in: Circle())
                                .offset(x: 6, y: 6)
                        }
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(choice.title)
                        .font(RadarFont.ui(15, .semibold))
                        .foregroundStyle(Color.radarText)
                    Text(choice.subtitle)
                        .font(RadarFont.body(12))
                        .foregroundStyle(Color.radarText3)
                }
            }
            .frame(minWidth: size, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isChanging)
        .accessibilityLabel("\(choice.title) app icon, \(choice.subtitle)")
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    private func select(_ choice: AppIconChoice) {
        guard choice != icons.current, !isChanging else { return }
        isChanging = true
        Task { @MainActor in
            defer { isChanging = false }
            do {
                try await icons.select(choice)
                Haptics.play(.success)
                toasts.show(choice == .standard ? "Back to the standard icon" : "App icon changed to \(choice.title)", icon: .check)
            } catch {
                Haptics.play(.warning)
                toasts.show("Couldn't change the app icon", icon: .x)
            }
        }
    }
}

/// Design-review controls for feature flags: shows what the server says and lets you
/// override it locally, so gated features can be tested before any backend is live.
struct FeatureFlagControls: View {
    @Environment(FeatureFlags.self) private var flags

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(flags.isRemoteConfigured
                 ? "Remote flags are connected."
                 : "Remote flags aren't connected yet, so every flag is off unless overridden here.")
                .font(RadarFont.body(13))
                .foregroundStyle(Color.radarText2)

            ForEach(FeatureFlag.allCases, id: \.self) { flag in
                row(flag)
            }

            if flags.isRemoteConfigured {
                Button("Refresh from server") {
                    Task { await flags.refresh(force: true) }
                }
                .font(RadarFont.ui(13, .bold))
                .foregroundStyle(Color.radarAccentText)
            }
        }
    }

    private func row(_ flag: FeatureFlag) -> some View {
        let binding = Binding<Bool>(
            get: { flags.isEnabled(flag) },
            set: { flags.setOverride(flag, $0) }
        )
        return VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: binding) {
                Text(flag.title)
                    .font(RadarFont.ui(16, .semibold))
                    .foregroundStyle(Color.radarText)
            }
            .tint(Color.radarAccent)
            Text(source(of: flag))
                .font(RadarFont.body(12))
                .foregroundStyle(Color.radarText3)
            if flags.override(flag) != nil {
                Button("Clear override") { flags.setOverride(flag, nil) }
                    .font(RadarFont.ui(12, .bold))
                    .foregroundStyle(Color.radarAccentText)
            }
        }
    }

    private func source(of flag: FeatureFlag) -> String {
        let server = flags.remoteValue(flag).map { $0 ? "on" : "off" } ?? "not set"
        if let local = flags.override(flag) {
            return "Local override: \(local ? "on" : "off") · Server: \(server)"
        }
        return "Server: \(server) · Default: \(flag.defaultValue ? "on" : "off")"
    }
}
