//
//  MainTabView.swift
//  findfriends
//

import SwiftUI
import MapKit

/// Find My–style shell: full-bleed map + floating sheet with tabs inside the sheet.
/// All secondary screens push in one NavigationStack (no nested sheets).
struct MainTabView: View {
    @Environment(AppSession.self) private var session

    @State private var locationManager = LocationManager()
    @State private var selectedTab: AppTab = .people
    @State private var myPlaceName: String?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedFriendID: String?
    @State private var selectedFriend: FriendPresence?
    @State private var showingAddFriend = false
    @State private var showingStatusEditor = false
    @State private var didCenterInitially = false
    @State private var showingSheet = true

    private var account: AccountUser? { session.account }
    private var friends: [FriendPresence] { session.friends }
    private var isRootSheetPage: Bool {
        selectedFriend == nil && !showingAddFriend && !showingStatusEditor
    }

    var body: some View {
        ZStack {
            mapLayer

            if locationManager.authorizationStatus == .denied ||
                locationManager.authorizationStatus == .restricted {
                locationDeniedOverlay
            }
        }
        .sheet(isPresented: $showingSheet) {
            sheetContent
                .presentationDetents([.fraction(0.38), .medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationCornerRadius(28)
                .interactiveDismissDisabled()
        }
        .tint(.green)
        .onAppear {
            locationManager.requestPermission()
        }
        .onChange(of: locationManager.currentLocation) { _, location in
            guard let location else { return }
            session.publishLocationIfNeeded(location)
            Task {
                myPlaceName = await locationManager.reverseGeocode(location)
            }
            if !didCenterInitially {
                didCenterInitially = true
                centerOnMe()
            }
        }
        .onChange(of: selectedTab) { _, tab in
            switch tab {
            case .me:
                centerOnMe()
            case .people:
                centerOnNearbyFriends()
            }
        }
    }

    // MARK: - Sheet (single NavigationStack — no nested sheets)

    private var sheetContent: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case .people:
                        PeopleListSheet(
                            placeName: myPlaceName,
                            onSelectFriend: { friend in
                                centerOnFriend(friend)
                                selectedFriend = friend
                            },
                            onAddFriend: { showingAddFriend = true }
                        )
                    case .me:
                        MeProfileView(
                            placeName: myPlaceName,
                            onEditStatus: { showingStatusEditor = true },
                            onAddFriend: { showingAddFriend = true },
                            onShowOnMap: { centerOnMe() }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if isRootSheetPage {
                    Divider()
                    FindFriendsTabBar(selection: $selectedTab)
                }
            }
            .navigationDestination(item: $selectedFriend) { friend in
                FriendDetailView(friend: friend) {
                    centerOnFriend(friend)
                }
            }
            .navigationDestination(isPresented: $showingAddFriend) {
                AddFriendView()
            }
            .navigationDestination(isPresented: $showingStatusEditor) {
                if let account {
                    StatusEditorView(account: account)
                }
            }
        }
    }

    // MARK: - Map

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            if let location = locationManager.currentLocation,
               let account,
               account.isSharingLocation {
                Annotation("Me", coordinate: location.coordinate) {
                    mapPin(
                        initials: account.initials,
                        colorHex: account.avatarColorHex,
                        status: account.displayStatus,
                        isSelected: selectedFriendID == nil
                    )
                    .onTapGesture {
                        selectedTab = .me
                        centerOnMe()
                    }
                }
            }

            ForEach(friends) { friend in
                if let coordinate = friend.coordinate {
                    Annotation(friend.displayName, coordinate: coordinate) {
                        mapPin(
                            initials: friend.initials,
                            colorHex: friend.avatarColorHex,
                            status: friend.displayStatus,
                            isSelected: selectedFriendID == friend.id
                        )
                        .onTapGesture {
                            selectedTab = .people
                            selectedFriendID = friend.id
                            centerOnFriend(friend)
                            selectedFriend = friend
                        }
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .ignoresSafeArea()
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

    private func centerOnFriend(_ friend: FriendPresence) {
        guard let coordinate = friend.coordinate else { return }
        selectedFriendID = friend.id
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1500,
                longitudinalMeters: 1500
            ))
        }
    }

    private func centerOnNearbyFriends() {
        guard let myLocation = locationManager.currentLocation else {
            centerOnMe()
            return
        }

        let friendsWithLocation = friends.compactMap { friend -> (FriendPresence, CLLocation)? in
            guard let coordinate = friend.coordinate else { return nil }
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            return (friend, location)
        }
        .sorted { lhs, rhs in
            myLocation.distance(from: lhs.1) < myLocation.distance(from: rhs.1)
        }

        guard !friendsWithLocation.isEmpty else {
            centerOnMe()
            return
        }

        let nearby = friendsWithLocation.prefix(5)
        selectedFriendID = nearby.first?.0.id

        var coordinates: [CLLocationCoordinate2D] = [myLocation.coordinate]
        coordinates.append(contentsOf: nearby.map(\.1.coordinate))

        withAnimation {
            cameraPosition = .region(regionFitting(coordinates))
        }
    }

    private func regionFitting(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard let first = coordinates.first else {
            return MKCoordinateRegion()
        }

        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude

        for coordinate in coordinates.dropFirst() {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.8, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.8, 0.01)
        )

        return MKCoordinateRegion(center: center, span: span)
    }
}
