//
//  FriendRowView.swift
//  findfriends
//

import SwiftUI
import MapKit

struct FriendRowView: View {
    let name: String
    let initials: String
    let colorHex: String
    let subtitle: String
    let status: String?
    let lastUpdated: Date?
    var isMe: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            FriendAvatarView(
                initials: initials,
                colorHex: colorHex,
                showsStatusRing: status != nil
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(name)
                        .font(.body.weight(.semibold))
                    if isMe {
                        Text("You")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let status {
                    Text(status)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            if let lastUpdated {
                Text(lastUpdated, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.vertical, 4)
    }
}
