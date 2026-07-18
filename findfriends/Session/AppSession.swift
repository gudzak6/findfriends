//
//  AppSession.swift
//  findfriends
//

import Foundation
import CoreLocation
import SwiftData
import Observation

enum SessionPhase: Equatable {
    case launching
    case needsConfiguration
    case signedOut
    case signedIn
}

@MainActor
@Observable
final class AppSession {
    private(set) var phase: SessionPhase = .launching
    private(set) var account: AccountUser?
    private(set) var friends: [FriendPresence] = []
    private(set) var savedPhones: [String: String] = [:]
    private(set) var lastError: String?
    private(set) var isSavingStatus = false
    private(set) var activeInvite: FriendInvite?

    private let auth: AuthServiceProtocol
    private let users: UserRepositoryProtocol
    private let friendships: FriendshipRepositoryProtocol
    private var localStore: LocalProfileStore?
    private var modelContext: ModelContext?

    private var authTask: Task<Void, Never>?
    private var userListenTask: Task<Void, Never>?
    private var friendsListTask: Task<Void, Never>?
    private var savedPhonesTask: Task<Void, Never>?
    private var friendListenTasks: [String: Task<Void, Never>] = [:]
    private var statusWriteTask: Task<Void, Never>?
    private var locationWriteTask: Task<Void, Never>?

    private let statusWriteDelayNanoseconds: UInt64 = 250_000_000
    private let locationMinInterval: TimeInterval = 20
    private let locationMinDistanceMeters: CLLocationDistance = 40
    private var lastPublishedLocation: CLLocation?
    private var lastLocationPublishAt: Date?

    init(
        auth: AuthServiceProtocol,
        users: UserRepositoryProtocol,
        friendships: FriendshipRepositoryProtocol
    ) {
        self.auth = auth
        self.users = users
        self.friendships = friendships
    }

    static func makeLive() -> AppSession {
        FirebaseBootstrap.configureIfPossible()
        if FirebaseBootstrap.isConfigured {
            let users = FirestoreUserRepository()
            let auth = FirebaseAuthService(users: users)
            let friendships = FirestoreFriendshipRepository()
            return AppSession(auth: auth, users: users, friendships: friendships)
        }
        return AppSession(
            auth: UnconfiguredAuthService(),
            users: UnconfiguredUserRepository(),
            friendships: UnconfiguredFriendshipRepository()
        )
    }

    func attach(modelContext: ModelContext) {
        self.modelContext = modelContext
        localStore = LocalProfileStore(context: modelContext)
        clearLegacyDemoFriends(in: modelContext)
        start()
    }

    func start() {
        guard FirebaseBootstrap.isConfigured else {
            phase = .needsConfiguration
            return
        }

        authTask?.cancel()
        authTask = Task { [weak self] in
            guard let self else { return }
            for await userID in auth.authStateChanges() {
                await self.handleAuthChange(userID)
            }
        }
    }

    func signUp(email: String, password: String, displayName: String, phoneNumber: String?) async {
        lastError = nil
        do {
            let user = try await auth.signUp(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                displayName: displayName,
                phoneNumber: phoneNumber
            )
            applySignedIn(user)
        } catch {
            lastError = (error as? AuthError)?.errorDescription ?? error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        lastError = nil
        do {
            let user = try await auth.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            applySignedIn(user)
        } catch {
            lastError = (error as? AuthError)?.errorDescription ?? error.localizedDescription
        }
    }

    func signOut() {
        do {
            try auth.signOut()
            stopFriendSync()
            savedPhonesTask?.cancel()
            userListenTask?.cancel()
            statusWriteTask?.cancel()
            locationWriteTask?.cancel()
            account = nil
            friends = []
            savedPhones = [:]
            activeInvite = nil
            localStore?.clear()
            phase = .signedOut
        } catch {
            lastError = error.localizedDescription
        }
    }

    func setStatus(text: String?, emoji: String?, duration: StatusDuration) {
        guard var current = account else { return }

        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()
        let next: PresenceStatus
        if let trimmed, !trimmed.isEmpty {
            next = PresenceStatus(
                text: trimmed,
                emoji: emoji?.nilIfEmpty,
                kind: .manual,
                updatedAt: now,
                expiresAt: duration.expiresAt(from: now)
            )
        } else {
            next = .empty
        }

        current.status = next
        current.updatedAt = now
        account = current
        localStore?.upsert(from: current)
        scheduleStatusWrite(next)
    }

    func setMyPhoneNumber(_ phone: String?) {
        guard var current = account else { return }
        let normalized = AccountUser.normalizedPhone(phone)
        current.phoneNumber = normalized
        current.updatedAt = Date()
        account = current
        localStore?.upsert(from: current)

        Task {
            do {
                try await users.updatePhoneNumber(userID: current.id, phoneNumber: normalized)
            } catch {
                await MainActor.run { lastError = error.localizedDescription }
            }
        }
    }

    func saveFriendPhone(friendID: String, phone: String?) {
        guard let ownerID = account?.id else { return }
        let normalized = AccountUser.normalizedPhone(phone)

        if let normalized {
            savedPhones[friendID] = normalized
        } else {
            savedPhones.removeValue(forKey: friendID)
        }
        applySavedPhonesToFriends()

        Task {
            do {
                try await users.saveFriendPhone(ownerID: ownerID, friendID: friendID, phoneNumber: normalized)
            } catch {
                await MainActor.run { lastError = error.localizedDescription }
            }
        }
    }

    func setSharingLocation(_ isSharing: Bool) {
        guard var current = account else { return }
        current.isSharingLocation = isSharing
        if !isSharing {
            current.latitude = nil
            current.longitude = nil
            current.locationUpdatedAt = nil
            lastPublishedLocation = nil
            lastLocationPublishAt = nil
        }
        current.updatedAt = Date()
        account = current
        localStore?.upsert(from: current)

        Task {
            do {
                try await users.updateSharing(userID: current.id, isSharingLocation: isSharing)
            } catch {
                await MainActor.run { lastError = error.localizedDescription }
            }
        }
    }

    /// Throttled location publish for friends map sync.
    func publishLocationIfNeeded(_ location: CLLocation) {
        guard let account, account.isSharingLocation else { return }

        if let lastAt = lastLocationPublishAt,
           let last = lastPublishedLocation,
           Date().timeIntervalSince(lastAt) < locationMinInterval,
           location.distance(from: last) < locationMinDistanceMeters {
            return
        }

        lastPublishedLocation = location
        lastLocationPublishAt = Date()

        var updated = account
        updated.latitude = location.coordinate.latitude
        updated.longitude = location.coordinate.longitude
        updated.locationUpdatedAt = Date()
        self.account = updated

        locationWriteTask?.cancel()
        locationWriteTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await users.updateLocation(userID: updated.id, coordinate: location.coordinate)
            } catch {
                await MainActor.run { self.lastError = error.localizedDescription }
            }
        }
    }

    func createInvite() async {
        lastError = nil
        guard let account else { return }
        do {
            activeInvite = try await friendships.createInvite(from: account)
        } catch {
            lastError = (error as? FriendshipError)?.errorDescription ?? error.localizedDescription
        }
    }

    func acceptInvite(code: String) async -> Bool {
        lastError = nil
        guard let account else { return false }
        do {
            try await friendships.acceptInvite(code: code, acceptor: account)
            return true
        } catch {
            lastError = (error as? FriendshipError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    // MARK: - Private

    private func handleAuthChange(_ userID: String?) async {
        guard let userID else {
            stopFriendSync()
            savedPhonesTask?.cancel()
            userListenTask?.cancel()
            account = nil
            friends = []
            savedPhones = [:]
            localStore?.clear()
            phase = .signedOut
            return
        }

        if let cached = localStore?.cachedProfile(for: userID)?.asAccountUser() {
            account = cached
            phase = .signedIn
        }

        do {
            if let remote = try await users.fetchUser(id: userID) {
                applySignedIn(remote)
            } else if account == nil {
                phase = .signedOut
            }
        } catch {
            lastError = error.localizedDescription
            if account == nil { phase = .signedOut }
        }

        startListening(to: userID)
        startFriendSync(for: userID)
        startSavedPhonesSync(for: userID)
    }

    private func applySignedIn(_ user: AccountUser) {
        account = user
        localStore?.upsert(from: user)
        phase = .signedIn
    }

    private func startListening(to userID: String) {
        userListenTask?.cancel()
        userListenTask = Task { [weak self] in
            guard let self else { return }
            for await remote in users.observeUser(id: userID) {
                guard !Task.isCancelled, let remote else { continue }
                if let local = self.account,
                   let localUpdated = local.status.updatedAt,
                   let remoteUpdated = remote.status.updatedAt,
                   localUpdated > remoteUpdated {
                    continue
                }
                self.applySignedIn(remote)
            }
        }
    }

    private func startFriendSync(for userID: String) {
        stopFriendSync()
        friendsListTask = Task { [weak self] in
            guard let self else { return }
            for await friendIDs in friendships.observeFriendIDs(for: userID) {
                guard !Task.isCancelled else { return }
                self.reconcileFriendListeners(friendIDs)
            }
        }
    }

    private func stopFriendSync() {
        friendsListTask?.cancel()
        friendsListTask = nil
        for task in friendListenTasks.values {
            task.cancel()
        }
        friendListenTasks.removeAll()
        friends = []
    }

    private func startSavedPhonesSync(for userID: String) {
        savedPhonesTask?.cancel()
        savedPhonesTask = Task { [weak self] in
            guard let self else { return }
            for await phones in users.observeSavedPhones(ownerID: userID) {
                guard !Task.isCancelled else { return }
                self.savedPhones = phones
                self.applySavedPhonesToFriends()
            }
        }
    }

    private func reconcileFriendListeners(_ friendIDs: [String]) {
        let desired = Set(friendIDs)
        let current = Set(friendListenTasks.keys)

        for removed in current.subtracting(desired) {
            friendListenTasks[removed]?.cancel()
            friendListenTasks[removed] = nil
            friends.removeAll { $0.id == removed }
        }

        for added in desired.subtracting(current) {
            friendListenTasks[added] = Task { [weak self] in
                guard let self else { return }
                for await remote in users.observeUser(id: added) {
                    guard !Task.isCancelled else { return }
                    guard let remote else {
                        self.friends.removeAll { $0.id == added }
                        continue
                    }
                    self.upsertFriend(
                        FriendPresence(from: remote, savedPhoneNumber: self.savedPhones[remote.id])
                    )
                }
            }
        }
    }

    private func upsertFriend(_ friend: FriendPresence) {
        var updated = friend
        updated.savedPhoneNumber = savedPhones[friend.id]
        if let index = friends.firstIndex(where: { $0.id == friend.id }) {
            friends[index] = updated
        } else {
            friends.append(updated)
            friends.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        }
    }

    private func applySavedPhonesToFriends() {
        for index in friends.indices {
            friends[index].savedPhoneNumber = savedPhones[friends[index].id]
        }
    }

    private func scheduleStatusWrite(_ status: PresenceStatus) {
        statusWriteTask?.cancel()
        isSavingStatus = true
        statusWriteTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: statusWriteDelayNanoseconds)
            guard !Task.isCancelled, let userID = account?.id else { return }
            do {
                try await users.updateStatus(userID: userID, status: status)
                await MainActor.run { self.isSavingStatus = false }
            } catch {
                await MainActor.run {
                    self.isSavingStatus = false
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    private func clearLegacyDemoFriends(in context: ModelContext) {
        let descriptor = FetchDescriptor<Friend>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard !existing.isEmpty else { return }
        for friend in existing {
            context.delete(friend)
        }
        try? context.save()
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
