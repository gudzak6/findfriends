//
//  FriendDetailView.swift
//  findfriends
//

import SwiftUI
import MapKit

struct FriendDetailView: View {
    @Environment(AppSession.self) private var session

    let friend: FriendPresence
    let onCenterOnMap: () -> Void

    @State private var placeName: String?

    private var liveFriend: FriendPresence {
        session.friends.first(where: { $0.id == friend.id }) ?? friend
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                FriendAvatarView(
                    initials: liveFriend.initials,
                    colorHex: liveFriend.avatarColorHex,
                    size: 88,
                    showsStatusRing: liveFriend.displayStatus != nil
                )

                VStack(spacing: 6) {
                    Text(liveFriend.displayName)
                        .font(.title2.weight(.bold))

                    if let phone = AccountUser.normalizedPhone(liveFriend.phoneNumber) {
                        Text(phone)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let placeName {
                        Text(placeName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if !liveFriend.isSharingLocation {
                        Text("Location not shared")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let lastUpdated = liveFriend.lastUpdated {
                        Text("Updated \(lastUpdated, style: .relative) ago")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                if let status = liveFriend.displayStatus {
                    VStack(spacing: 8) {
                        Text("Status")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(status)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                    }
                    .padding(.horizontal)
                }

                VStack(spacing: 12) {
                    if liveFriend.canMessage {
                        actionButton(title: "Message", icon: "message.fill", color: .green) {
                            openMessages()
                        }
                    }

                    if liveFriend.coordinate != nil {
                        actionButton(title: "Show on Map", icon: "map", color: .teal, action: onCenterOnMap)
                        actionButton(title: "Get Directions", icon: "arrow.triangle.turn.up.right.diamond", color: .orange) {
                            openDirections()
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground))
        .task {
            if let coordinate = liveFriend.coordinate {
                placeName = await reverseGeocode(coordinate)
            }
        }
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
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
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
        .tint(color)
    }

    private func openMessages() {
        guard let recipient = liveFriend.messageRecipient else { return }
        // Open the Messages app (iMessage when available) addressed to their number/email.
        MessagesLauncher.open(recipient: recipient)
    }

    private func openDirections() {
        guard let coordinate = liveFriend.coordinate else { return }
        let placemark = MKPlacemark(coordinate: coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = liveFriend.displayName
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async -> String? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemark = try? await geocoder.reverseGeocodeLocation(location).first else {
            return String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
        }
        if let locality = placemark.locality, let name = placemark.name {
            return "\(name), \(locality)"
        }
        return placemark.locality ?? placemark.name
    }
}
