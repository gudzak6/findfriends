//
//  AccountUser.swift
//  findfriends
//

import Foundation

struct AccountUser: Identifiable, Equatable, Sendable {
    let id: String
    var email: String
    var displayName: String
    var phoneNumber: String?
    var initials: String
    var avatarColorHex: String
    var isSharingLocation: Bool
    var status: PresenceStatus
    var latitude: Double?
    var longitude: Double?
    var locationUpdatedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    var displayStatus: String? { status.displayText }

    static func makeNew(id: String, email: String, displayName: String) -> AccountUser {
        let now = Date()
        return AccountUser(
            id: id,
            email: email,
            displayName: displayName,
            phoneNumber: nil,
            initials: Self.initials(from: displayName),
            avatarColorHex: Self.colorHex(for: id),
            isSharingLocation: true,
            status: .empty,
            latitude: nil,
            longitude: nil,
            locationUpdatedAt: nil,
            createdAt: now,
            updatedAt: now
        )
    }

    static func normalizedPhone(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let allowed = trimmed.filter { $0.isNumber || $0 == "+" }
        return allowed.isEmpty ? nil : allowed
    }

    static func initials(from name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first.map(String.init) }
        let value = letters.joined().uppercased()
        return value.isEmpty ? "ME" : value
    }

    static func colorHex(for id: String) -> String {
        let palette = ["5856D6", "34C759", "007AFF", "FF9500", "AF52DE", "FF2D55", "64D2FF"]
        var hasher = Hasher()
        hasher.combine(id)
        let hash = abs(hasher.finalize())
        return palette[hash % palette.count]
    }
}
