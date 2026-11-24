import SwiftUI

struct SettingsButton: ToolbarContent {
    @Binding var show: Bool
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Settings", systemImage: "gearshape") { show = true }
        }
    }
}

extension View {
    func settingsSheet(_ show: Binding<Bool>) -> some View {
        sheet(isPresented: show) { SettingsScreen().presentationDetents([.large]) }
    }
}

/// A plain `Form`: every control is the system's own.
struct SettingsScreen: View {
    @Environment(SettingsStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $store.settings.theme) {
                        ForEach(ThemePreference.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    Toggle("Signal effects", isOn: $store.settings.fx)
                    Toggle("Haptic feedback", isOn: $store.settings.haptics)
                }
                Section("Discovery") {
                    Picker("Region", selection: $store.settings.country) {
                        ForEach(DemoCatalog.shared.countries) { Text($0.name).tag($0.code) }
                    }
                    Toggle("Hide explicit tracks", isOn: $store.settings.hideExplicit)
                    NavigationLink("Favourite genres") { GenrePicker() }
                }
                AppIconPickerSection()
                #if DEBUG
                Section("Developer · feature flags") { FeatureFlagControls() }
                #endif
                Section {
                    Button("Reset settings", role: .destructive) { confirmReset = true }
                } footer: {
                    Text("RADAR uses a fictional demo catalog. Tracks have no audio; imported files do.")
                }
            }
            .radarListBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .confirmationDialog("Reset settings?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { store.reset() }
            }
        }
        .tint(Color.radarAccentText)
    }
}

private struct GenrePicker: View {
    @Environment(SettingsStore.self) private var store
    var body: some View {
        List(DemoCatalog.shared.genres) { g in
            Button { store.toggleGenre(g.name) } label: {
                HStack {
                    Text(g.name)
                    Spacer()
                    if store.settings.genres.contains(g.name) { Image(systemName: "checkmark").foregroundStyle(Color.radarAccentText) }
                }
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("Favourite genres")
        .radarListBackground()
    }
}
