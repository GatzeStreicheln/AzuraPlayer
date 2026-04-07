import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled = false
    @AppStorage("appLanguage") private var lang = "en"
    @AppStorage("themeColor") private var themeColorName = "blue"

    private var accentColor: Color { AppTheme.color(for: themeColorName) }

    var body: some View {
        NavigationStack {
            List {
                Section(tr("Appearance", "Erscheinungsbild", lang)) {
                    Toggle(tr("Enable Dark Mode", "Dark Mode aktivieren", lang), isOn: $isDarkModeEnabled)
                    Text(tr(
                        "When enabled, the app is always shown in dark mode.",
                        "Wenn aktiviert, wird die App immer im Dunklen Modus angezeigt.",
                        lang
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Picker(tr("Language", "Sprache", lang), selection: $lang) {
                        Text("English").tag("en")
                        Text("Deutsch").tag("de")
                    }
                    .id(themeColorName)

                    Picker(tr("Accent Color", "Akzentfarbe", lang), selection: $themeColorName) {
                        ForEach(AppTheme.options, id: \.name) { option in
                            HStack {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 14, height: 14)
                                Text(lang == "de" ? option.nameDE : option.nameEN)
                            }
                            .tag(option.name)
                        }
                    }
                    .id(themeColorName)
                }

                Section(tr("Links & Contact", "Links & Kontakt", lang)) {
                    if let url = URL(string: "https://github.com/GatzeStreicheln/AzuraPlayer") {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                    .foregroundStyle(.secondary)
                                Text("GitHub")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    if let url = URL(string: "https://gatzestreicheln.github.io/AzuraPlayer/privacy.html") {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "hand.raised")
                                    .foregroundStyle(.secondary)
                                Text(tr("Privacy Policy", "Datenschutz", lang))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    if let url = URL(string: "mailto:vasco@vkugler.ch") {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundStyle(.secondary)
                                Text(tr("Contact", "Kontakt", lang))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Info") {
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
                    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
                    Text("AzuraPlayer \(version) (\(build))")
                    Text(tr(
                        "AzuraPlayer is an unofficial app and has no affiliation with AzuraCast or its developers.",
                        "AzuraPlayer ist eine inoffizielle App und steht in keiner Verbindung zu AzuraCast oder dessen Entwicklern.",
                        lang
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Color.clear
                    .frame(height: 16)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(tr("Settings", "Einstellungen", lang))
            .tint(accentColor)
        }
    }
}

