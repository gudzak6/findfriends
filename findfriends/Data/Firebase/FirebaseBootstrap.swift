//
//  FirebaseBootstrap.swift
//  findfriends
//

import Foundation
import FirebaseCore
import FirebaseFirestore

enum FirebaseBootstrap {
    private(set) static var isConfigured = false

    static func configureIfPossible() {
        guard !isConfigured else { return }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            #if DEBUG
            print("[Firebase] GoogleService-Info.plist missing — remote auth/storage disabled.")
            #endif
            return
        }

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        configureFirestorePerformance()
        isConfigured = true
    }

    /// Persistent cache + unlimited local size so map/status UI stays snappy offline.
    private static func configureFirestorePerformance() {
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(
            sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited)
        )
        Firestore.firestore().settings = settings
    }
}
