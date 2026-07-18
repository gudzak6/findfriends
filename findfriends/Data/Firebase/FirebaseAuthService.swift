//
//  FirebaseAuthService.swift
//  findfriends
//

import Foundation
import FirebaseAuth

final class FirebaseAuthService: AuthServiceProtocol {
    private let auth: Auth
    private let users: UserRepositoryProtocol

    init(auth: Auth = Auth.auth(), users: UserRepositoryProtocol) {
        self.auth = auth
        self.users = users
    }

    var currentUserID: String? { auth.currentUser?.uid }

    func signUp(email: String, password: String, displayName: String, phoneNumber: String?) async throws -> AccountUser {
        guard FirebaseBootstrap.isConfigured else { throw AuthError.notConfigured }

        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let change = result.user.createProfileChangeRequest()
            change.displayName = displayName
            try await change.commitChanges()

            var account = AccountUser.makeNew(
                id: result.user.uid,
                email: email.lowercased(),
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            account.phoneNumber = AccountUser.normalizedPhone(phoneNumber)
            try await users.createUser(account)
            return account
        } catch {
            throw map(error)
        }
    }

    func signIn(email: String, password: String) async throws -> AccountUser {
        guard FirebaseBootstrap.isConfigured else { throw AuthError.notConfigured }

        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            if let existing = try await users.fetchUser(id: result.user.uid) {
                return existing
            }

            // Repair path: Auth user exists but profile doc is missing.
            let name = result.user.displayName?.nilIfEmpty
                ?? email.split(separator: "@").first.map(String.init)
                ?? "Friend"
            let account = AccountUser.makeNew(
                id: result.user.uid,
                email: email.lowercased(),
                displayName: name
            )
            try await users.createUser(account)
            return account
        } catch {
            throw map(error)
        }
    }

    func signOut() throws {
        guard FirebaseBootstrap.isConfigured else { throw AuthError.notConfigured }
        try auth.signOut()
    }

    func authStateChanges() -> AsyncStream<String?> {
        AsyncStream { continuation in
            let handle = auth.addStateDidChangeListener { _, user in
                continuation.yield(user?.uid)
            }
            continuation.onTermination = { _ in
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }

    private func map(_ error: Error) -> AuthError {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .network
        }

        let code = AuthErrorCode(rawValue: nsError.code)
        switch code {
        case .wrongPassword, .userNotFound, .invalidCredential, .invalidEmail:
            return .invalidCredentials
        case .emailAlreadyInUse:
            return .emailInUse
        case .weakPassword:
            return .weakPassword
        case .networkError:
            return .network
        default:
            return .unknown(error.localizedDescription)
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
