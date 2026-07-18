//
//  FriendPresence.swift
//  findfriends
//

import Foundation
import CoreLocation

struct FriendPresence: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    var displayName: String
    var email: String
    var phoneNumber: String?
    /// Number you saved for this friend (overrides their profile phone for messaging).
    var savedPhoneNumber: String?
    var initials: String
    var avatarColorHex: String
    var isSharingLocation: Bool
    var status: PresenceStatus
    var latitude: Double?
    var longitude: Double?
    var locationUpdatedAt: Date?

    var displayStatus: String? { status.displayText }

    var coordinate: CLLocationCoordinate2D? {
        guard isSharingLocation,
              let latitude,
              let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var lastUpdated: Date? {
        locationUpdatedAt ?? status.updatedAt
    }

    /// Uses their profile phone, otherwise email, for Messages / iMessage.
    var messageRecipient: String? {
        if let phone = AccountUser.normalizedPhone(phoneNumber) { return phone }
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return email.isEmpty ? nil : email
    }

    var canMessage: Bool { messageRecipient != nil }

    init(from user: AccountUser, savedPhoneNumber: String? = nil) {
        id = user.id
        displayName = user.displayName
        email = user.email
        phoneNumber = user.phoneNumber
        self.savedPhoneNumber = savedPhoneNumber
        initials = user.initials
        avatarColorHex = user.avatarColorHex
        isSharingLocation = user.isSharingLocation
        status = user.status
        latitude = user.latitude
        longitude = user.longitude
        locationUpdatedAt = user.locationUpdatedAt
    }
}

struct FriendInvite: Equatable, Sendable {
    let code: String
    let fromUserID: String
    let fromDisplayName: String
    let createdAt: Date
    let expiresAt: Date
    var status: String

    var isExpired: Bool { expiresAt <= Date() || status != "pending" }
}

enum FriendshipError: LocalizedError, Equatable {
    case invalidCode
    case expired
    case alreadyFriends
    case cannotAddSelf
    case notConfigured
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidCode: return "That invite code wasn’t found."
        case .expired: return "That invite has expired. Ask for a new one."
        case .alreadyFriends: return "You’re already friends."
        case .cannotAddSelf: return "You can’t add yourself."
        case .notConfigured: return "Firebase is not configured."
        case .unknown(let message): return message
        }
    }
}
