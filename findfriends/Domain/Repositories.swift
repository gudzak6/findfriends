//
//  Repositories.swift
//  findfriends
//

import Foundation
import CoreLocation

enum AuthError: LocalizedError, Equatable {
    case notConfigured
    case invalidCredentials
    case emailInUse
    case weakPassword
    case network
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Firebase is not configured. Add GoogleService-Info.plist (see FIREBASE_SETUP.md)."
        case .invalidCredentials:
            return "Invalid email or password."
        case .emailInUse:
            return "An account with this email already exists."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .network:
            return "Network error. Check your connection and try again."
        case .unknown(let message):
            return message
        }
    }
}

protocol AuthServiceProtocol: AnyObject {
    var currentUserID: String? { get }
    func signUp(email: String, password: String, displayName: String, phoneNumber: String?) async throws -> AccountUser
    func signIn(email: String, password: String) async throws -> AccountUser
    func signOut() throws
    func authStateChanges() -> AsyncStream<String?>
}

protocol UserRepositoryProtocol: AnyObject {
    func createUser(_ user: AccountUser) async throws
    func fetchUser(id: String) async throws -> AccountUser?
    func updateStatus(userID: String, status: PresenceStatus) async throws
    func updateSharing(userID: String, isSharingLocation: Bool) async throws
    func updateProfile(userID: String, displayName: String) async throws
    func updatePhoneNumber(userID: String, phoneNumber: String?) async throws
    func updateLocation(userID: String, coordinate: CLLocationCoordinate2D?) async throws
    func observeUser(id: String) -> AsyncStream<AccountUser?>
    func saveFriendPhone(ownerID: String, friendID: String, phoneNumber: String?) async throws
    func observeSavedPhones(ownerID: String) -> AsyncStream<[String: String]>
}

protocol FriendshipRepositoryProtocol: AnyObject {
    func createInvite(from user: AccountUser) async throws -> FriendInvite
    func acceptInvite(code: String, acceptor: AccountUser) async throws
    func observeFriendIDs(for userID: String) -> AsyncStream<[String]>
}
