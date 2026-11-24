import SwiftUI

/// "App icon" rows in Settings. Appears only when a choice exists beyond the standard icon.
struct AppIconPickerSection: View {
    @Environment(AppIconService.self) private var icons
    @Environment(FeatureFlags.self) private var flags
    @Environment(ToastCenter.self) private var toasts
    @State private var isChanging = false

    var body: some View {
        if icons.isPickerVisible(flags: flags) {
            Section {
                ForEach(icons.availableChoices(flags: flags)) { choice in
                    Button { select(choice) } label: {
                        HStack(spacing: 12) {
                            Image(choice.previewAsset).resizable().scaledToFit().frame(width: 52, height: 52)
                                .clipShape(.rect(cornerRadius: 52 * 0.2237, style: .continuous))
                            VStack(alignment: .leading) { Text(choice.title); Text(choice.subtitle).font(.caption).foregroundStyle(.secondary) }
                            Spacer()
                            if icons.current == choice { Image(systemName: "checkmark").foregroundStyle(Color.radarAccentText) }
                        }
                    }
                    .buttonStyle(.plain).disabled(isChanging)
                    .accessibilityAddTraits(icons.current == choice ? .isSelected : [])
                }
            } header: { Text("App icon") } footer: {
                Text("iOS asks you to confirm the change. Switch back any time.")
            }
            .onAppear { icons.refresh() }
        }
    }

    private func select(_ choice: AppIconChoice) {
        guard choice != icons.current, !isChanging else { return }
        isChanging = true
        Task { @MainActor in
            defer { isChanging = false }
            do {
                try await icons.select(choice)
                Haptics.play(.success)
                toasts.show(choice == .standard ? "Back to the standard icon" : "App icon changed to \(choice.title)", symbol: "checkmark")
            } catch {
                Haptics.play(.warning)
                toasts.show("Couldn't change the app icon", symbol: "xmark")
            }
        }
    }
}

/// Design-review controls for feature flags (DEBUG builds).
struct FeatureFlagControls: View {
    @Environment(FeatureFlags.self) private var flags

    var body: some View {
        Text(flags.isRemoteConfigured ? "Remote flags are connected." : "Remote flags aren't connected, so every flag is off unless overridden.")
            .font(.footnote).foregroundStyle(.secondary)
        ForEach(FeatureFlag.allCases, id: \.self) { flag in
            Toggle(isOn: Binding(get: { flags.isEnabled(flag) }, set: { flags.setOverride(flag, $0) })) {
                VStack(alignment: .leading) {
                    Text(flag.title)
                    Text(flags.override(flag) != nil ? "Local override" : "Server: \(flags.remoteValue(flag).map { $0 ? "on" : "off" } ?? "not set")")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .swipeActions { if flags.override(flag) != nil { Button("Clear") { flags.setOverride(flag, nil) } } }
        }
        if flags.isRemoteConfigured { Button("Refresh from server") { Task { await flags.refresh(force: true) } } }
    }
}
