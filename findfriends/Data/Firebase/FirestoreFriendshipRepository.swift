//
//  FirestoreFriendshipRepository.swift
//  findfriends
//

import Foundation
import FirebaseFirestore

final class FirestoreFriendshipRepository: FriendshipRepositoryProtocol {
    private let db: Firestore
    private let codeAlphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func createInvite(from user: AccountUser) async throws -> FriendInvite {
        let code = try await uniqueCode()
        let now = Date()
        let expires = now.addingTimeInterval(7 * 24 * 60 * 60)
        let data: [String: Any] = [
            FirestoreKeys.Invite.fromUserId: user.id,
            FirestoreKeys.Invite.fromDisplayName: user.displayName,
            FirestoreKeys.Invite.createdAt: Timestamp(date: now),
            FirestoreKeys.Invite.expiresAt: Timestamp(date: expires),
            FirestoreKeys.Invite.status: "pending",
        ]
        try await db.collection(FirestoreKeys.invites).document(code).setData(data)
        return FriendInvite(
            code: code,
            fromUserID: user.id,
            fromDisplayName: user.displayName,
            createdAt: now,
            expiresAt: expires,
            status: "pending"
        )
    }

    func acceptInvite(code: String, acceptor: AccountUser) async throws {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty else { throw FriendshipError.invalidCode }

        let inviteRef = db.collection(FirestoreKeys.invites).document(normalized)
        let snapshot = try await inviteRef.getDocument()
        guard snapshot.exists, let data = snapshot.data() else {
            throw FriendshipError.invalidCode
        }

        let fromUserID = data[FirestoreKeys.Invite.fromUserId] as? String ?? ""
        let status = data[FirestoreKeys.Invite.status] as? String ?? ""
        let expiresAt = (data[FirestoreKeys.Invite.expiresAt] as? Timestamp)?.dateValue() ?? .distantPast

        guard fromUserID != acceptor.id else { throw FriendshipError.cannotAddSelf }
        guard status == "pending", expiresAt > Date() else { throw FriendshipError.expired }

        let friendshipID = FirestoreKeys.friendshipID(fromUserID, acceptor.id)
        let friendshipRef = db.collection(FirestoreKeys.friendships).document(friendshipID)
        let members = [fromUserID, acceptor.id].sorted()

        do {
            let existing = try await friendshipRef.getDocument()
            if existing.exists { throw FriendshipError.alreadyFriends }
        } catch let error as FriendshipError {
            throw error
        } catch {
            // If rules were stale, continue and let create be the source of truth.
            #if DEBUG
            print("[FriendshipRepository] friendship pre-check: \(error.localizedDescription)")
            #endif
        }

        let batch = db.batch()
        batch.setData([
            FirestoreKeys.Friendship.memberIds: members,
            FirestoreKeys.Friendship.createdAt: FieldValue.serverTimestamp(),
            FirestoreKeys.Friendship.createdBy: acceptor.id,
        ], forDocument: friendshipRef)
        batch.updateData([
            FirestoreKeys.Invite.status: "accepted",
            FirestoreKeys.Invite.acceptedBy: acceptor.id,
        ], forDocument: inviteRef)

        do {
            try await batch.commit()
        } catch {
            let message = error.localizedDescription.lowercased()
            if message.contains("permission") {
                throw FriendshipError.unknown(
                    "Firestore blocked the friendship write. Re-publish firebase/firestore.rules, then try again."
                )
            }
            throw FriendshipError.unknown(error.localizedDescription)
        }
    }

    func observeFriendIDs(for userID: String) -> AsyncStream<[String]> {
        AsyncStream { continuation in
            let query = db.collection(FirestoreKeys.friendships)
                .whereField(FirestoreKeys.Friendship.memberIds, arrayContains: userID)

            let listener = query.addSnapshotListener { snapshot, error in
                if let error {
                    #if DEBUG
                    print("[FriendshipRepository] listen error: \(error.localizedDescription)")
                    #endif
                    return
                }

                let ids: [String] = (snapshot?.documents ?? []).compactMap { doc in
                    let members = doc.data()[FirestoreKeys.Friendship.memberIds] as? [String] ?? []
                    return members.first { $0 != userID }
                }
                continuation.yield(Array(Set(ids)).sorted())
            }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    private func uniqueCode() async throws -> String {
        for _ in 0..<8 {
            let code = String((0..<6).map { _ in codeAlphabet.randomElement()! })
            let snapshot = try await db.collection(FirestoreKeys.invites).document(code).getDocument()
            if !snapshot.exists { return code }
        }
        throw FriendshipError.unknown("Could not generate invite code. Try again.")
    }
}
