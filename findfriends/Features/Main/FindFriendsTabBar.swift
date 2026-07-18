//
//  FindFriendsTabBar.swift
//  findfriends
//

import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case people
    case me

    var title: String {
        switch self {
        case .people: return "People"
        case .me: return "Me"
        }
    }

    var systemImage: String {
        switch self {
        case .people: return "person.2.fill"
        case .me: return "location.north.line.fill"
        }
    }
}

/// Tab bar that lives inside the bottom sheet (Find My style), not the system tab bar.
struct FindFriendsTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 20, weight: .semibold))
                        Text(tab.title)
                            .font(.caption2.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(selection == tab ? Color.accentColor : Color.secondary)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 2)
        .background(.bar)
    }
}
