//
//  EditMyPhoneView.swift
//  findfriends
//

import SwiftUI

struct EditMyPhoneView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var session

    @State private var phone = ""

    var body: some View {
        Form {
            Section {
                TextField("Phone number", text: $phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
            } footer: {
                Text("Friends use this number to Message you in iMessage.")
            }

            if !(session.account?.phoneNumber ?? "").isEmpty {
                Section {
                    Button("Remove Number", role: .destructive) {
                        session.setMyPhoneNumber(nil)
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("Phone Number")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    session.setMyPhoneNumber(phone)
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            phone = session.account?.phoneNumber ?? ""
        }
    }
}
