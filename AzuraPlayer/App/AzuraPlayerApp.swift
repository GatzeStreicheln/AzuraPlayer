//
//  AzuraPlayerApp.swift
//  AzuraPlayer
//

import SwiftUI

@main
struct AzuraPlayerApp: App {
    @StateObject private var store = StationStore()
    @StateObject private var player = AudioPlayerService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(player)
        }
    }
}
