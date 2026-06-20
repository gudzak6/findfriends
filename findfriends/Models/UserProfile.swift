//
//  UserProfile.swift
//  findfriends
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var status: String?
    var statusEmoji: String?
    var isSharingLocation: Bool
    var statusUpdatedAt: Date?

    init(
        id: UUID = UUID(),
        name: String = "Me",
        status: String? = nil,
        statusEmoji: String? = nil,
        isSharingLocation: Bool = true,
        statusUpdatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.statusEmoji = statusEmoji
        self.isSharingLocation = isSharingLocation
        self.statusUpdatedAt = statusUpdatedAt
    }

    var displayStatus: String? {
        guard let status, !status.isEmpty else { return nil }
        if let emoji = statusEmoji, !emoji.isEmpty {
            return "\(emoji) \(status)"
        }
        return status
    }
}
