//
//  UnconfiguredBackend.swift
//  findfriends
//

import Foundation
import CoreLocation

/// Safe stand-ins so we never call `Auth.auth()` / `Firestore.firestore()` before configure.
final class UnconfiguredAuthService: AuthServiceProtocol {
    var currentUserID: String? { nil }

    func signUp(email: String, password: String, displayName: String, phoneNumber: String?) async throws -> AccountUser {
        throw AuthError.notConfigured
    }

    func signIn(email: String, password: String) async throws -> AccountUser {
        throw AuthError.notConfigured
    }

    func signOut() throws {
        throw AuthError.notConfigured
    }

    func authStateChanges() -> AsyncStream<String?> {
        AsyncStream { continuation in
            continuation.yield(nil)
            continuation.finish()
        }
    }
}

final class UnconfiguredUserRepository: UserRepositoryProtocol {
    func createUser(_ user: AccountUser) async throws {
        throw AuthError.notConfigured
    }

    func fetchUser(id: String) async throws -> AccountUser? {
        throw AuthError.notConfigured
    }

    func updateStatus(userID: String, status: PresenceStatus) async throws {
        throw AuthError.notConfigured
    }

    func updateSharing(userID: String, isSharingLocation: Bool) async throws {
        throw AuthError.notConfigured
    }

    func updateProfile(userID: String, displayName: String) async throws {
        throw AuthError.notConfigured
    }

    func updatePhoneNumber(userID: String, phoneNumber: String?) async throws {
        throw AuthError.notConfigured
    }

    func updateLocation(userID: String, coordinate: CLLocationCoordinate2D?) async throws {
        throw AuthError.notConfigured
    }

    func observeUser(id: String) -> AsyncStream<AccountUser?> {
        AsyncStream { continuation in
            continuation.yield(nil)
            continuation.finish()
        }
    }

    func saveFriendPhone(ownerID: String, friendID: String, phoneNumber: String?) async throws {
        throw AuthError.notConfigured
    }

    func observeSavedPhones(ownerID: String) -> AsyncStream<[String: String]> {
        AsyncStream { continuation in
            continuation.yield([:])
            continuation.finish()
        }
    }
}

final class UnconfiguredFriendshipRepository: FriendshipRepositoryProtocol {
    func createInvite(from user: AccountUser) async throws -> FriendInvite {
        throw FriendshipError.notConfigured
    }

    func acceptInvite(code: String, acceptor: AccountUser) async throws {
        throw FriendshipError.notConfigured
    }

    func observeFriendIDs(for userID: String) -> AsyncStream<[String]> {
        AsyncStream { continuation in
            continuation.yield([])
            continuation.finish()
        }
    }
}
