//
//  PeopleListSheet.swift
//  findfriends
//

import SwiftUI

struct PeopleListSheet: View {
    @Environment(AppSession.self) private var session

    let placeName: String?
    let onSelectFriend: (FriendPresence) -> Void
    var onAddFriend: () -> Void = {}

    private var friends: [FriendPresence] { session.friends }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text("People")
                    .font(.largeTitle.weight(.bold))
                Spacer()
                Button(action: onAddFriend) {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color(.tertiarySystemFill)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 4)

            List {
                if friends.isEmpty {
                    ContentUnavailableView {
                        Label("No friends yet", systemImage: "person.2")
                    } description: {
                        Text("Add friends to see them on the map.")
                    } actions: {
                        Button("Add Friend", action: onAddFriend)
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(friends) { friend in
                        Button {
                            onSelectFriend(friend)
                        } label: {
                            FriendRowView(
                                name: friend.displayName,
                                initials: friend.initials,
                                colorHex: friend.avatarColorHex,
                                subtitle: friendSubtitle(friend),
                                status: friend.displayStatus,
                                lastUpdated: friend.lastUpdated
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func friendSubtitle(_ friend: FriendPresence) -> String {
        if friend.coordinate != nil {
            return "Sharing location"
        }
        return friend.isSharingLocation ? "Location unavailable" : "Not sharing"
    }
}
