//
//  FriendsListSheet.swift
//  findfriends
//

import SwiftUI
import SwiftData

struct FriendsListSheet: View {
    @Query(sort: \Friend.name) private var friends: [Friend]
    @Query private var profiles: [UserProfile]

    let locationManager: LocationManager
    let placeName: String?
    let onSelectFriend: (Friend) -> Void
    let onSelectMe: () -> Void

    @State private var showingStatusEditor = false
    @State private var selectedFriend: Friend?

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            List {
                if let profile {
                    Section {
                        Button {
                            onSelectMe()
                        } label: {
                            FriendRowView(
                                name: profile.name,
                                initials: "ME",
                                colorHex: "5856D6",
                                subtitle: profile.isSharingLocation
                                    ? (placeName ?? "Sharing your location")
                                    : "Location sharing off",
                                status: profile.displayStatus,
                                lastUpdated: profile.statusUpdatedAt,
                                isMe: true
                            )
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button {
                                showingStatusEditor = true
                            } label: {
                                Label("Status", systemImage: "text.bubble")
                            }
                            .tint(.green)
                        }
                    } header: {
                        Text("Me")
                    }
                }

                Section {
                    ForEach(friends) { friend in
                        Button {
                            onSelectFriend(friend)
                            selectedFriend = friend
                        } label: {
                            FriendRowView(
                                name: friend.name,
                                initials: friend.initials,
                                colorHex: friend.avatarColorHex,
                                subtitle: friend.isSharingLocation ? "Sharing location" : "Not sharing",
                                status: friend.displayStatus,
                                lastUpdated: friend.lastUpdated
                            )
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("People")
                } footer: {
                    Text("Friends can see your location and status when sharing is on.")
                        .font(.caption)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("People")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingStatusEditor = true
                    } label: {
                        Label("Set Status", systemImage: "text.bubble.fill")
                    }
                    .tint(.green)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if let profile {
                            Toggle("Share My Location", isOn: Bindable(profile).isSharingLocation)
                        }
                        Button("Add Friend", systemImage: "person.badge.plus") {}
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingStatusEditor) {
                if let profile {
                    StatusEditorView(profile: profile)
                }
            }
            .sheet(item: $selectedFriend) { friend in
                NavigationStack {
                    FriendDetailView(friend: friend) {
                        onSelectFriend(friend)
                        selectedFriend = nil
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { selectedFriend = nil }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
}
