//
//  LocalProfileStore.swift
//  findfriends
//

import Foundation
import SwiftData

/// SwiftData mirror of the signed-in account for offline-first UI reads.
@MainActor
final class LocalProfileStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func cachedProfile(for userID: String) -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.remoteID == userID }
        )
        return try? context.fetch(descriptor).first
    }

    func upsert(from account: AccountUser) {
        if let existing = cachedProfile(for: account.id) {
            existing.apply(account)
        } else {
            // Keep a single local "me" profile; replace any leftover demo row.
            let all = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
            for profile in all where profile.remoteID != account.id {
                context.delete(profile)
            }
            context.insert(UserProfile(from: account))
        }
        try? context.save()
    }

    func clear() {
        let all = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        for profile in all {
            context.delete(profile)
        }
        try? context.save()
    }
}
