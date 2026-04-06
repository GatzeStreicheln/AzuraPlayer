import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled = false

    var body: some View {
        NavigationStack {
            List {
                Section("Erscheinungsbild") {
                    Toggle("Dark Mode aktivieren", isOn: $isDarkModeEnabled)

                    Text("Wenn aktiviert, wird die App immer im Dunklen Modus angezeigt.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Info") {
                    Text("AzuraPlayer v0.1")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
            .background(Color(UIColor.systemBackground))
            .navigationTitle("Einstellungen")
        }
    }
}
