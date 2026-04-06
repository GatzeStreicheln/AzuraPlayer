//
//  RadioStation.swift
//  AzuraPlayer
//
//  Created by Vasco Kugler on 06.04.2026.
//
import Foundation
import SwiftUI

struct RadioStation: Identifiable, Codable {
    var id: UUID = UUID()
    var customName: String?         // nil = automatisch vom Server holen
    var streamURL: String
    var apiURL: String              // AzuraCast Now Playing URL
    var customImageData: Data?      // Foto aus Galerie
    var showSongArt: Bool = false   // Schalter: Song-Cover statt Sender-Cover
    var sortOrder: Int = 0

    // Wird NICHT gespeichert – kommt live von der API
    var fetchedStationName: String?
    var fetchedStationArtURL: String?

    // Anzeigename: custom hat Vorrang, sonst Server-Name, sonst URL
    var displayName: String {
        if let custom = customName, !custom.isEmpty {
            return custom
        }
        if let fetched = fetchedStationName, !fetched.isEmpty {
            return fetched
        }
        return streamURL
    }

    enum CodingKeys: String, CodingKey {
        case id, customName, streamURL, apiURL
        case customImageData, showSongArt, sortOrder
    }
}

