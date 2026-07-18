//
//  FirestoreKeys.swift
//  findfriends
//

import Foundation

enum FirestoreKeys {
    static let users = "users"
    static let friendships = "friendships"
    static let invites = "invites"
    static let savedContacts = "savedContacts"

    enum User {
        static let email = "email"
        static let displayName = "displayName"
        static let phoneNumber = "phoneNumber"
        static let initials = "initials"
        static let avatarColorHex = "avatarColorHex"
        static let isSharingLocation = "isSharingLocation"
        static let statusText = "statusText"
        static let statusEmoji = "statusEmoji"
        static let statusKind = "statusKind"
        static let statusUpdatedAt = "statusUpdatedAt"
        static let statusExpiresAt = "statusExpiresAt"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let locationUpdatedAt = "locationUpdatedAt"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
    }

    enum SavedContact {
        static let phoneNumber = "phoneNumber"
        static let updatedAt = "updatedAt"
    }

    enum Friendship {
        static let memberIds = "memberIds"
        static let createdAt = "createdAt"
        static let createdBy = "createdBy"
    }

    enum Invite {
        static let fromUserId = "fromUserId"
        static let fromDisplayName = "fromDisplayName"
        static let createdAt = "createdAt"
        static let expiresAt = "expiresAt"
        static let status = "status"
        static let acceptedBy = "acceptedBy"
    }

    static func friendshipID(_ a: String, _ b: String) -> String {
        a < b ? "\(a)_\(b)" : "\(b)_\(a)"
    }
}
