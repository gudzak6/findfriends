//
//  FirestoreUserRepository.swift
//  findfriends
//

import Foundation
import CoreLocation
import FirebaseFirestore

/// Remote user store. Status/location writes are field-level patches to minimize bandwidth.
final class FirestoreUserRepository: UserRepositoryProtocol {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    private func userDoc(_ id: String) -> DocumentReference {
        db.collection(FirestoreKeys.users).document(id)
    }

    func createUser(_ user: AccountUser) async throws {
        try await userDoc(user.id).setData(user.firestoreData())
    }

    func fetchUser(id: String) async throws -> AccountUser? {
        let snapshot = try await userDoc(id).getDocument(source: .default)
        guard snapshot.exists, let data = snapshot.data() else { return nil }
        return AccountUser(id: id, data: data)
    }

    func updateStatus(userID: String, status: PresenceStatus) async throws {
        try await userDoc(userID).updateData(AccountUser.statusPatch(status))
    }

    func updateSharing(userID: String, isSharingLocation: Bool) async throws {
        var patch: [String: Any] = [
            FirestoreKeys.User.isSharingLocation: isSharingLocation,
            FirestoreKeys.User.updatedAt: FieldValue.serverTimestamp(),
        ]
        if !isSharingLocation {
            patch.merge(AccountUser.locationPatch(nil)) { _, new in new }
        }
        try await userDoc(userID).updateData(patch)
    }

    func updateProfile(userID: String, displayName: String) async throws {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        try await userDoc(userID).updateData([
            FirestoreKeys.User.displayName: trimmed,
            FirestoreKeys.User.initials: AccountUser.initials(from: trimmed),
            FirestoreKeys.User.updatedAt: FieldValue.serverTimestamp(),
        ])
    }

    func updatePhoneNumber(userID: String, phoneNumber: String?) async throws {
        try await userDoc(userID).updateData([
            FirestoreKeys.User.phoneNumber: AccountUser.normalizedPhone(phoneNumber) ?? NSNull(),
            FirestoreKeys.User.updatedAt: FieldValue.serverTimestamp(),
        ])
    }

    func updateLocation(userID: String, coordinate: CLLocationCoordinate2D?) async throws {
        try await userDoc(userID).updateData(AccountUser.locationPatch(coordinate))
    }

    func observeUser(id: String) -> AsyncStream<AccountUser?> {
        AsyncStream { continuation in
            let listener = userDoc(id).addSnapshotListener(includeMetadataChanges: false) { snapshot, error in
                if let error {
                    #if DEBUG
                    print("[FirestoreUserRepository] listen error: \(error.localizedDescription)")
                    #endif
                    return
                }
                guard let snapshot, snapshot.exists, let data = snapshot.data() else {
                    continuation.yield(nil)
                    return
                }
                continuation.yield(AccountUser(id: id, data: data))
            }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    func saveFriendPhone(ownerID: String, friendID: String, phoneNumber: String?) async throws {
        let ref = userDoc(ownerID)
            .collection(FirestoreKeys.savedContacts)
            .document(friendID)

        if let phone = AccountUser.normalizedPhone(phoneNumber) {
            try await ref.setData([
                FirestoreKeys.SavedContact.phoneNumber: phone,
                FirestoreKeys.SavedContact.updatedAt: FieldValue.serverTimestamp(),
            ])
        } else {
            try await ref.delete()
        }
    }

    func observeSavedPhones(ownerID: String) -> AsyncStream<[String: String]> {
        AsyncStream { continuation in
            let listener = userDoc(ownerID)
                .collection(FirestoreKeys.savedContacts)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        #if DEBUG
                        print("[FirestoreUserRepository] saved contacts error: \(error.localizedDescription)")
                        #endif
                        return
                    }

                    var map: [String: String] = [:]
                    for doc in snapshot?.documents ?? [] {
                        if let phone = AccountUser.normalizedPhone(
                            doc.data()[FirestoreKeys.SavedContact.phoneNumber] as? String
                        ) {
                            map[doc.documentID] = phone
                        }
                    }
                    continuation.yield(map)
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
}
