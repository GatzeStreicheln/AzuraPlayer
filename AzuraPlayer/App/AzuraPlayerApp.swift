import SwiftUI

/// Localized string: returns English by default, German if lang == "de".
/// Use with @AppStorage("appLanguage") for SwiftUI reactivity.
func tr(_ en: String, _ de: String, _ lang: String) -> String {
    lang == "de" ? de : en
}

@main
struct AzuraPlayerApp: App {
    @StateObject private var store = StationStore()
    @StateObject private var player = AudioPlayerService.shared
    @AppStorage("themeColor") private var themeColorName = "blue"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(player)
                .tint(AppTheme.color(for: themeColorName))
        }
    }
}
