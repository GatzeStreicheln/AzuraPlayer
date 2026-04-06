//
//  StationListView.swift
//  AzuraPlayer
//

import SwiftUI

struct StationListView: View {
    @EnvironmentObject var store: StationStore
    @EnvironmentObject var player: AudioPlayerService
    @Binding var showPlayer: Bool
    
    @State private var showAddStation = false
    @State private var editingStation: RadioStation? = nil
    @State private var stationToDelete: RadioStation? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.stations) { station in
                    StationRowView(
                        station: station,
                        isPlaying: player.currentStation?.id == station.id && player.isPlaying,
                        isBuffering: player.currentStation?.id == station.id && player.isBuffering
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        player.play(station: station)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            stationToDelete = station
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                        
                        Button {
                            editingStation = station
                        } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }
                        .tint(.accentColor)
                    }
                    // Hintergrund der Zeilen: Transparent, damit der Listen-Hintergrund durchscheint
                    .listRowBackground(
                        Color(UIColor.systemBackground)
                            .opacity(0.0)
                    )
                }
                .onMove { from, to in
                    store.move(from: from, to: to)
                }
                
                VStack {
                    Color.clear
                        .frame(height: 100)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            // FIX: Nutzung von systemBackground statt hartem Schwarz
            // Passt sich automatisch an Light/Dark Mode an
            .background(Color(UIColor.systemBackground).ignoresSafeArea())
            .navigationTitle("AzuraPlayer")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddStation = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                    }
                }
            }
            .confirmationDialog("Radiosender löschen?", isPresented: .constant(stationToDelete != nil), presenting: stationToDelete) { station in
                Button("Löschen", role: .destructive) {
                    store.delete(station: station)
                    if player.currentStation?.id == station.id {
                        player.stop()
                    }
                }
                Button("Abbrechen", role: .cancel) {
                    stationToDelete = nil
                }
            } message: { station in
                Text("Möchten Sie '\(station.displayName)' wirklich entfernen?")
            }
            .sheet(isPresented: $showAddStation) {
                AddEditStationView(store: store)
            }
            .sheet(item: $editingStation) { station in
                AddEditStationView(store: store, editStation: station)
            }
        }
        // WICHTIG: Kein eigenes preferredColorScheme hier!
        // Das wird global von ContentView/Settings gesteuert.
    }
}
