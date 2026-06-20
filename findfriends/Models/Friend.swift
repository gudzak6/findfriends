//
//  Friend.swift
//  findfriends
//

import Foundation
import CoreLocation
import SwiftData

@Model
final class Friend {
    var id: UUID
    var name: String
    var initials: String
    var avatarColorHex: String
    var latitude: Double
    var longitude: Double
    var status: String?
    var statusEmoji: String?
    var lastUpdated: Date
    var isSharingLocation: Bool

    init(
        id: UUID = UUID(),
        name: String,
        initials: String,
        avatarColorHex: String,
        latitude: Double,
        longitude: Double,
        status: String? = nil,
        statusEmoji: String? = nil,
        lastUpdated: Date = Date(),
        isSharingLocation: Bool = true
    ) {
        self.id = id
        self.name = name
        self.initials = initials
        self.avatarColorHex = avatarColorHex
        self.latitude = latitude
        self.longitude = longitude
        self.status = status
        self.statusEmoji = statusEmoji
        self.lastUpdated = lastUpdated
        self.isSharingLocation = isSharingLocation
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var displayStatus: String? {
        guard let status, !status.isEmpty else { return nil }
        if let emoji = statusEmoji, !emoji.isEmpty {
            return "\(emoji) \(status)"
        }
        return status
    }
}
