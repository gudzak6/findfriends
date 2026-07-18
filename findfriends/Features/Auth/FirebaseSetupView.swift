//
//  FirebaseSetupView.swift
//  findfriends
//

import SwiftUI

struct FirebaseSetupView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Connect Firebase", systemImage: "flame.fill")
        } description: {
            Text("Add GoogleService-Info.plist from your Firebase project, enable Email/Password auth, and deploy the rules in /firebase. See FIREBASE_SETUP.md.")
        } actions: {
            if let url = URL(string: "https://console.firebase.google.com") {
                Link("Open Firebase Console", destination: url)
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
            }
        }
        .padding()
    }
}
