//
//  ContentView.swift
//  findfriends
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MapFriendsView()
            .tint(.green)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Friend.self, UserProfile.self], inMemory: true)
}
