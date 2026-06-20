//
//  FriendAvatarView.swift
//  findfriends
//

import SwiftUI

struct FriendAvatarView: View {
    let initials: String
    let colorHex: String
    var size: CGFloat = 44
    var showsStatusRing: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: colorHex))
                .frame(width: size, height: size)

            Text(initials)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(.white)

            if showsStatusRing {
                Circle()
                    .strokeBorder(.green, lineWidth: 3)
                    .frame(width: size + 4, height: size + 4)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (128, 128, 128)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
