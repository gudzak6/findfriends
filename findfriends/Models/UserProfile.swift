//
//  UserProfile.swift
//  findfriends
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var remoteID: String
    var name: String
    var email: String
    var initials: String
    var avatarColorHex: String
    var status: String?
    var statusEmoji: String?
    var statusKind: String?
    var isSharingLocation: Bool
    var statusUpdatedAt: Date?
    var statusExpiresAt: Date?

    init(
        id: UUID = UUID(),
        remoteID: String = "",
        name: String = "Me",
        email: String = "",
        initials: String = "ME",
        avatarColorHex: String = "5856D6",
        status: String? = nil,
        statusEmoji: String? = nil,
        statusKind: String? = nil,
        isSharingLocation: Bool = true,
        statusUpdatedAt: Date? = nil,
        statusExpiresAt: Date? = nil
    ) {
        self.id = id
        self.remoteID = remoteID
        self.name = name
        self.email = email
        self.initials = initials
        self.avatarColorHex = avatarColorHex
        self.status = status
        self.statusEmoji = statusEmoji
        self.statusKind = statusKind
        self.isSharingLocation = isSharingLocation
        self.statusUpdatedAt = statusUpdatedAt
        self.statusExpiresAt = statusExpiresAt
    }

    convenience init(from account: AccountUser) {
        self.init(
            remoteID: account.id,
            name: account.displayName,
            email: account.email,
            initials: account.initials,
            avatarColorHex: account.avatarColorHex,
            status: account.status.text,
            statusEmoji: account.status.emoji,
            statusKind: account.status.kind?.rawValue,
            isSharingLocation: account.isSharingLocation,
            statusUpdatedAt: account.status.updatedAt,
            statusExpiresAt: account.status.expiresAt
        )
    }

    func apply(_ account: AccountUser) {
        remoteID = account.id
        name = account.displayName
        email = account.email
        initials = account.initials
        avatarColorHex = account.avatarColorHex
        status = account.status.text
        statusEmoji = account.status.emoji
        statusKind = account.status.kind?.rawValue
        isSharingLocation = account.isSharingLocation
        statusUpdatedAt = account.status.updatedAt
        statusExpiresAt = account.status.expiresAt
    }

    var presence: PresenceStatus {
        PresenceStatus(
            text: status,
            emoji: statusEmoji,
            kind: statusKind.flatMap(StatusKind.init(rawValue:)),
            updatedAt: statusUpdatedAt,
            expiresAt: statusExpiresAt
        ).effective
    }

    var displayStatus: String? { presence.displayText }

    func asAccountUser() -> AccountUser? {
        guard !remoteID.isEmpty else { return nil }
        return AccountUser(
            id: remoteID,
            email: email,
            displayName: name,
            phoneNumber: nil,
            initials: initials,
            avatarColorHex: avatarColorHex,
            isSharingLocation: isSharingLocation,
            status: presence,
            latitude: nil,
            longitude: nil,
            locationUpdatedAt: nil,
            createdAt: statusUpdatedAt ?? Date(),
            updatedAt: statusUpdatedAt ?? Date()
        )
    }
}
