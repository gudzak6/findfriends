//
//  FriendDetailView.swift
//  findfriends
//

import SwiftUI
import MapKit

struct FriendDetailView: View {
    let friend: Friend
    let onCenterOnMap: () -> Void

    @State private var placeName: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                FriendAvatarView(
                    initials: friend.initials,
                    colorHex: friend.avatarColorHex,
                    size: 88,
                    showsStatusRing: friend.displayStatus != nil
                )

                VStack(spacing: 6) {
                    Text(friend.name)
                        .font(.title2.weight(.bold))

                    if let placeName {
                        Text(placeName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("Updated \(friend.lastUpdated, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                if let status = friend.displayStatus {
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
                    actionButton(title: "Show on Map", icon: "map", color: .green, action: onCenterOnMap)
                    actionButton(title: "Get Directions", icon: "arrow.triangle.turn.up.right.diamond", color: .blue) {
                        openDirections()
                    }
                    actionButton(title: "Notify Me", icon: "bell", color: .orange) {}
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground))
        .task {
            placeName = await reverseGeocode(friend.coordinate)
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

    private func openDirections() {
        let placemark = MKPlacemark(coordinate: friend.coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = friend.name
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
