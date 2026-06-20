//
//  FriendsDataService.swift
//  findfriends
//

import Foundation
import CoreLocation
import SwiftData

enum FriendsDataService {
    static func seedIfNeeded(context: ModelContext, near coordinate: CLLocationCoordinate2D?) {
        let friendDescriptor = FetchDescriptor<Friend>()
        let profileDescriptor = FetchDescriptor<UserProfile>()

        let existingFriends = (try? context.fetch(friendDescriptor)) ?? []
        let existingProfiles = (try? context.fetch(profileDescriptor)) ?? []

        if existingProfiles.isEmpty {
            context.insert(UserProfile(name: "Me"))
        }

        guard existingFriends.isEmpty else { return }

        let base = coordinate ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

        let samples: [(String, String, String, Double, Double, String?, String?)] = [
            ("Alex Rivera", "AR", "34C759", 0.008, 0.012, "Getting coffee", "☕️"),
            ("Jordan Lee", "JL", "007AFF", -0.006, 0.004, "At the gym", "💪"),
            ("Sam Chen", "SC", "FF9500", 0.003, -0.009, "Studying at library", "📚"),
            ("Taylor Brooks", "TB", "AF52DE", -0.011, -0.005, nil, nil),
            ("Morgan Walsh", "MW", "FF2D55", 0.015, -0.002, "On a run", "🏃"),
        ]

        for sample in samples {
            let friend = Friend(
                name: sample.0,
                initials: sample.1,
                avatarColorHex: sample.2,
                latitude: base.latitude + sample.3,
                longitude: base.longitude + sample.4,
                status: sample.5,
                statusEmoji: sample.6,
                lastUpdated: Date().addingTimeInterval(Double.random(in: -3600 ... -120))
            )
            context.insert(friend)
        }

        try? context.save()
    }

    static func simulateFriendMovement(friends: [Friend]) {
        for friend in friends where friend.isSharingLocation {
            friend.latitude += Double.random(in: -0.0003 ... 0.0003)
            friend.longitude += Double.random(in: -0.0003 ... 0.0003)
            friend.lastUpdated = Date()
        }
        try? friends.first?.modelContext?.save()
    }
}
