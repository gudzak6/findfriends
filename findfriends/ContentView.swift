//
//  ContentView.swift
//  findfriends
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            switch session.phase {
            case .launching:
                ProgressView("Loading…")
            case .needsConfiguration:
                FirebaseSetupView()
            case .signedOut:
                AuthView()
            case .signedIn:
                MainTabView()
            }
        }
        .tint(.green)
        .onAppear {
            session.attach(modelContext: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .environment(AppSession.makeLive())
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
