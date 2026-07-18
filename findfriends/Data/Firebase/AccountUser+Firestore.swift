//
//  AccountUser+Firestore.swift
//  findfriends
//

import Foundation
import CoreLocation
import FirebaseFirestore

extension AccountUser {
    init?(id: String, data: [String: Any]) {
        guard
            let email = data[FirestoreKeys.User.email] as? String,
            let displayName = data[FirestoreKeys.User.displayName] as? String
        else { return nil }

        self.id = id
        self.email = email
        self.displayName = displayName
        self.phoneNumber = Self.normalizedPhone(data[FirestoreKeys.User.phoneNumber] as? String)
        self.initials = data[FirestoreKeys.User.initials] as? String ?? Self.initials(from: displayName)
        self.avatarColorHex = data[FirestoreKeys.User.avatarColorHex] as? String ?? Self.colorHex(for: id)
        self.isSharingLocation = data[FirestoreKeys.User.isSharingLocation] as? Bool ?? true
        self.latitude = data[FirestoreKeys.User.latitude] as? Double
        self.longitude = data[FirestoreKeys.User.longitude] as? Double
        self.locationUpdatedAt = (data[FirestoreKeys.User.locationUpdatedAt] as? Timestamp)?.dateValue()
        self.createdAt = (data[FirestoreKeys.User.createdAt] as? Timestamp)?.dateValue() ?? Date()
        self.updatedAt = (data[FirestoreKeys.User.updatedAt] as? Timestamp)?.dateValue() ?? Date()

        let rawStatus = PresenceStatus(
            text: data[FirestoreKeys.User.statusText] as? String,
            emoji: data[FirestoreKeys.User.statusEmoji] as? String,
            kind: (data[FirestoreKeys.User.statusKind] as? String).flatMap(StatusKind.init(rawValue:)),
            updatedAt: (data[FirestoreKeys.User.statusUpdatedAt] as? Timestamp)?.dateValue(),
            expiresAt: (data[FirestoreKeys.User.statusExpiresAt] as? Timestamp)?.dateValue()
        )
        self.status = rawStatus.effective
    }

    func firestoreData(includingTimestamps: Bool = true) -> [String: Any] {
        var data: [String: Any] = [
            FirestoreKeys.User.email: email,
            FirestoreKeys.User.displayName: displayName,
            FirestoreKeys.User.phoneNumber: phoneNumber as Any,
            FirestoreKeys.User.initials: initials,
            FirestoreKeys.User.avatarColorHex: avatarColorHex,
            FirestoreKeys.User.isSharingLocation: isSharingLocation,
            FirestoreKeys.User.statusText: status.text as Any,
            FirestoreKeys.User.statusEmoji: status.emoji as Any,
            FirestoreKeys.User.statusKind: status.kind?.rawValue as Any,
            FirestoreKeys.User.statusUpdatedAt: status.updatedAt.map { Timestamp(date: $0) } as Any,
            FirestoreKeys.User.statusExpiresAt: status.expiresAt.map { Timestamp(date: $0) } as Any,
            FirestoreKeys.User.latitude: latitude as Any,
            FirestoreKeys.User.longitude: longitude as Any,
            FirestoreKeys.User.locationUpdatedAt: locationUpdatedAt.map { Timestamp(date: $0) } as Any,
        ]

        if includingTimestamps {
            data[FirestoreKeys.User.createdAt] = Timestamp(date: createdAt)
            data[FirestoreKeys.User.updatedAt] = Timestamp(date: updatedAt)
        }

        return data
    }

    static func statusPatch(_ status: PresenceStatus) -> [String: Any] {
        [
            FirestoreKeys.User.statusText: status.text as Any,
            FirestoreKeys.User.statusEmoji: status.emoji as Any,
            FirestoreKeys.User.statusKind: status.kind?.rawValue as Any,
            FirestoreKeys.User.statusUpdatedAt: status.updatedAt.map { Timestamp(date: $0) } as Any,
            FirestoreKeys.User.statusExpiresAt: status.expiresAt.map { Timestamp(date: $0) } as Any,
            FirestoreKeys.User.updatedAt: FieldValue.serverTimestamp(),
        ]
    }

    static func locationPatch(_ coordinate: CLLocationCoordinate2D?) -> [String: Any] {
        if let coordinate {
            return [
                FirestoreKeys.User.latitude: coordinate.latitude,
                FirestoreKeys.User.longitude: coordinate.longitude,
                FirestoreKeys.User.locationUpdatedAt: FieldValue.serverTimestamp(),
            ]
        }
        return [
            FirestoreKeys.User.latitude: NSNull(),
            FirestoreKeys.User.longitude: NSNull(),
            FirestoreKeys.User.locationUpdatedAt: NSNull(),
        ]
    }
}
