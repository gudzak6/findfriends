//
//  MeProfileView.swift
//  findfriends
//

import SwiftUI

struct MeProfileView: View {
    @Environment(AppSession.self) private var session

    let placeName: String?
    var onEditStatus: () -> Void = {}
    var onAddFriend: () -> Void = {}
    var onShowOnMap: () -> Void = {}

    @State private var showingEditPhone = false

    private var account: AccountUser? { session.account }

    var body: some View {
        Group {
            if let account {
                ScrollView {
                    VStack(spacing: 24) {
                        FriendAvatarView(
                            initials: account.initials,
                            colorHex: account.avatarColorHex,
                            size: 88,
                            showsStatusRing: account.displayStatus != nil
                        )

                        VStack(spacing: 6) {
                            Text(account.displayName)
                                .font(.title2.weight(.bold))

                            if let phone = AccountUser.normalizedPhone(account.phoneNumber) {
                                Text(phone)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            if let placeName, account.isSharingLocation {
                                Text(placeName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else if !account.isSharingLocation {
                                Text("Location not shared")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            if let updated = account.status.updatedAt ?? account.locationUpdatedAt {
                                Text("Updated \(updated, style: .relative) ago")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        VStack(spacing: 8) {
                            Text("Status")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)

                            Button(action: onEditStatus) {
                                Text(account.displayStatus ?? "Set a status")
                                    .font(.title3)
                                    .foregroundStyle(account.displayStatus == nil ? .secondary : .primary)
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(.secondarySystemGroupedBackground))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)

                        VStack(spacing: 12) {
                            actionButton(
                                title: account.phoneNumber == nil ? "Add Phone Number" : "Edit Phone Number",
                                icon: "phone.fill"
                            ) {
                                showingEditPhone = true
                            }

                            actionButton(
                                title: "Show on Map",
                                icon: "map",
                                action: onShowOnMap
                            )

                            actionButton(
                                title: account.isSharingLocation ? "Stop Sharing Location" : "Share My Location",
                                icon: account.isSharingLocation ? "location.slash.fill" : "location.fill"
                            ) {
                                session.setSharingLocation(!account.isSharingLocation)
                            }

                            actionButton(
                                title: "Add Friend",
                                icon: "person.badge.plus",
                                action: onAddFriend
                            )

                            actionButton(
                                title: "Sign Out",
                                icon: "rectangle.portrait.and.arrow.right",
                                destructive: true
                            ) {
                                session.signOut()
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                }
                .background(Color(.systemGroupedBackground))
                .navigationDestination(isPresented: $showingEditPhone) {
                    EditMyPhoneView()
                }
            }
        }
    }

    private func actionButton(
        title: String,
        icon: String,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .font(.body.weight(.medium))
            .foregroundStyle(destructive ? Color.red : Color.primary)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}
