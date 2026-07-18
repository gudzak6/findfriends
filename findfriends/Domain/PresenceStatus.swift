//
//  PresenceStatus.swift
//  findfriends
//

import Foundation

enum StatusKind: String, Codable, Sendable {
    case manual
    case idle
    case away
}

struct PresenceStatus: Equatable, Hashable, Sendable {
    var text: String?
    var emoji: String?
    var kind: StatusKind?
    var updatedAt: Date?
    var expiresAt: Date?

    static let empty = PresenceStatus(
        text: nil,
        emoji: nil,
        kind: nil,
        updatedAt: nil,
        expiresAt: nil
    )

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt <= Date()
    }

    /// Effective status after applying expiration rules (client-side, zero network cost).
    var effective: PresenceStatus {
        isExpired ? .empty : self
    }

    var displayText: String? {
        let live = effective
        guard let text = live.text, !text.isEmpty else { return nil }
        if let emoji = live.emoji, !emoji.isEmpty {
            return "\(emoji) \(text)"
        }
        return text
    }
}

enum StatusDuration: String, CaseIterable, Identifiable {
    case twentyMinutes
    case oneHour
    case fourHours
    case endOfDay
    case untilCleared

    var id: String { rawValue }

    var title: String {
        switch self {
        case .twentyMinutes: return "20 minutes"
        case .oneHour: return "1 hour"
        case .fourHours: return "4 hours"
        case .endOfDay: return "End of day"
        case .untilCleared: return "Until I clear it"
        }
    }

    func expiresAt(from date: Date = Date()) -> Date? {
        switch self {
        case .twentyMinutes:
            return date.addingTimeInterval(20 * 60)
        case .oneHour:
            return date.addingTimeInterval(60 * 60)
        case .fourHours:
            return date.addingTimeInterval(4 * 60 * 60)
        case .endOfDay:
            return Calendar.current.nextDate(
                after: date,
                matching: DateComponents(hour: 23, minute: 59, second: 59),
                matchingPolicy: .nextTime
            )
        case .untilCleared:
            return nil
        }
    }
}
