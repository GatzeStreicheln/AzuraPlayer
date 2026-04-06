import Foundation
import SwiftUI
import Combine

class StationStore: ObservableObject {
    @Published var stations: [RadioStation] = []

    private let saveKey = "saved_stations"

    init() {
        load()
        stations.forEach { fetchStationName(for: $0) }
    }

    func add(station: RadioStation) {
        var s = station
        s.sortOrder = stations.count
        stations.append(s)
        save()
        fetchStationName(for: s)
    }

    func update(station: RadioStation) {
        if let idx = stations.firstIndex(where: { $0.id == station.id }) {
            stations[idx] = station
            save()
            fetchStationName(for: station)
        }
    }

    func delete(station: RadioStation) {
        stations.removeAll { $0.id == station.id }
        save()
    }

    func move(from: IndexSet, to: Int) {
        stations.move(fromOffsets: from, toOffset: to)
        save()
    }

    func fetchStationName(for station: RadioStation) {
        guard !station.apiURL.isEmpty,
              let url = URL(string: station.apiURL) else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(NowPlayingResponse.self, from: data)
                await MainActor.run {
                    if let idx = self.stations.firstIndex(where: { $0.id == station.id }) {
                        self.stations[idx].fetchedStationName = response.station.name
                    }
                }
            } catch {
                print("fetchStationName error: \(error)")
            }
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(stations) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([RadioStation].self, from: data) {
            stations = decoded
        }
    }
}
