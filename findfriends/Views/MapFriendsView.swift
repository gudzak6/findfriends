//
//  MapFriendsView.swift
//  findfriends
//

import SwiftUI
import MapKit
import SwiftData

struct MapFriendsView: View {
    @Query(sort: \Friend.name) private var friends: [Friend]
    @Query private var profiles: [UserProfile]

    @State private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedFriendID: UUID?
    @State private var myPlaceName: String?
    @State private var showingList = true
    @State private var movementTimer: Timer?

    @Environment(\.modelContext) private var modelContext

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack(alignment: .bottom) {
            mapLayer

            if locationManager.authorizationStatus == .denied ||
                locationManager.authorizationStatus == .restricted {
                locationDeniedOverlay
            }
        }
        .sheet(isPresented: $showingList) {
            FriendsListSheet(
                locationManager: locationManager,
                placeName: myPlaceName,
                onSelectFriend: centerOnFriend,
                onSelectMe: centerOnMe
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .interactiveDismissDisabled()
        }
        .onAppear {
            locationManager.requestPermission()
            seedData()
            startMovementSimulation()
        }
        .onDisappear {
            movementTimer?.invalidate()
            locationManager.stopUpdating()
        }
        .onChange(of: locationManager.currentLocation) { _, location in
            guard let location else { return }
            Task {
                myPlaceName = await locationManager.reverseGeocode(location)
            }
            if cameraPosition == .automatic {
                centerOnMe()
            }
        }
    }

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            if let location = locationManager.currentLocation, profile?.isSharingLocation == true {
                Annotation("Me", coordinate: location.coordinate) {
                    mapPin(initials: "ME", colorHex: "5856D6", status: profile?.displayStatus, isSelected: selectedFriendID == nil)
                        .onTapGesture { centerOnMe() }
                }
            }

            ForEach(friends.filter(\.isSharingLocation)) { friend in
                Annotation(friend.name, coordinate: friend.coordinate) {
                    mapPin(
                        initials: friend.initials,
                        colorHex: friend.avatarColorHex,
                        status: friend.displayStatus,
                        isSelected: selectedFriendID == friend.id
                    )
                    .onTapGesture {
                        selectedFriendID = friend.id
                        centerOnFriend(friend)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .ignoresSafeArea(edges: .top)
    }

    private func mapPin(initials: String, colorHex: String, status: String?, isSelected: Bool) -> some View {
        VStack(spacing: 4) {
            if let status {
                Text(status)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .lineLimit(1)
                    .frame(maxWidth: 120)
            }

            FriendAvatarView(initials: initials, colorHex: colorHex, size: isSelected ? 52 : 44)
                .shadow(color: .black.opacity(0.25), radius: isSelected ? 8 : 4, y: 2)
                .scaleEffect(isSelected ? 1.1 : 1)
                .animation(.spring(duration: 0.25), value: isSelected)
        }
    }

    private var locationDeniedOverlay: some View {
        VStack {
            Spacer()
            ContentUnavailableView {
                Label("Location Access Needed", systemImage: "location.slash")
            } description: {
                Text("Enable location in Settings to share your position with friends.")
            } actions: {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding()
            Spacer()
        }
    }

    private func seedData() {
        FriendsDataService.seedIfNeeded(
            context: modelContext,
            near: locationManager.currentLocation?.coordinate
        )
    }

    private func centerOnMe() {
        guard let coordinate = locationManager.currentLocation?.coordinate else { return }
        selectedFriendID = nil
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 2500,
                longitudinalMeters: 2500
            ))
        }
    }

    private func centerOnFriend(_ friend: Friend) {
        selectedFriendID = friend.id
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: friend.coordinate,
                latitudinalMeters: 1500,
                longitudinalMeters: 1500
            ))
        }
    }

    private func startMovementSimulation() {
        movementTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { _ in
            FriendsDataService.simulateFriendMovement(friends: friends)
        }
    }
}
