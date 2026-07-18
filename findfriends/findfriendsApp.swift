//
//  findfriendsApp.swift
//  findfriends
//

import SwiftUI
import SwiftData

@main
struct findfriendsApp: App {
    @State private var session = AppSession.makeLive()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            Friend.self, // kept so legacy demo rows can be wiped on launch
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Schema migration during rapid iteration — wipe local cache rather than crash.
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [fallback])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(session)
        }
        .modelContainer(sharedModelContainer)
    }
}
