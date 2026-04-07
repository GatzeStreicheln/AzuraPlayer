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

                Section(tr("Legal", "Rechtliches", lang)) {
                    NavigationLink(tr("Privacy Policy", "Datenschutz", lang)) {
                        LegalTextView(
                            title: tr("Privacy Policy", "Datenschutz", lang),
                            content: lang == "de" ? datenschutzTextDE : datenschutzTextEN
                        )
                    }
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

struct LegalTextView: View {
    let title: String
    let content: String

    private var attributedContent: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        return (try? AttributedString(markdown: content, options: options)) ?? AttributedString(content)
    }

    var body: some View {
        ScrollView {
            Text(attributedContent)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Legal Texts

private let datenschutzTextDE = """
AzuraPlayer erfasst keine personenbezogenen Daten. Es findet kein Tracking statt, es wird keine Werbung eingeblendet, und es ist kein Benutzerkonto erforderlich.

**Gespeicherte Daten**
AzuraPlayer speichert die hinzugefügten Stationen ausschließlich lokal auf dem Gerät. Diese Daten verlassen das Gerät nicht und werden nicht übermittelt.

**Verbindung zu externen Servern**
Wird ein Radiostream abgerufen, verbindet sich die App direkt mit dem AzuraCast-Server der jeweiligen Station. Dabei können dort technische Daten wie die IP-Adresse anfallen. Dies liegt außerhalb des Einflussbereichs von AzuraPlayer und liegt in der Verantwortung des jeweiligen Stationsbetreibers.

**App Store**
Wird die App über den Apple App Store geladen, gelten zusätzlich die Datenschutzbestimmungen von Apple. Darauf besteht kein Einfluss seitens AzuraPlayer.
"""

private let datenschutzTextEN = """
AzuraPlayer does not collect any personal data. There is no tracking, no advertising, and no user account required.

**Stored Data**
AzuraPlayer stores the stations you add exclusively on your device. This data never leaves your device and is not transmitted anywhere.

**Connection to External Servers**
When a radio stream is accessed, the app connects directly to the AzuraCast server of the respective station. Technical data such as your IP address may be recorded there. This is outside the control of AzuraPlayer and is the responsibility of the respective station operator.

**App Store**
If you download the app via the Apple App Store, Apple's privacy policy also applies. AzuraPlayer has no influence over this.
"""

