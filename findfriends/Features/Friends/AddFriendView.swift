//
//  AddFriendView.swift
//  findfriends
//

import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var session

    @State private var code = ""
    @State private var isWorking = false

    var body: some View {
        Form {
            Section("Your invite code") {
                if let invite = session.activeInvite {
                    Text(invite.code)
                        .font(.system(.title, design: .monospaced).weight(.bold))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .textSelection(.enabled)

                    ShareLink(item: "Add me on Find Friends: \(invite.code)") {
                        Label("Share Code", systemImage: "square.and.arrow.up")
                    }

                    Text("Expires \(invite.expiresAt, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        Task {
                            isWorking = true
                            await session.createInvite()
                            isWorking = false
                        }
                    } label: {
                        if isWorking {
                            ProgressView()
                        } else {
                            Label("Generate Invite Code", systemImage: "plus.circle")
                        }
                    }
                    .disabled(isWorking)
                }
            }

            Section("Enter a friend’s code") {
                TextField("Code", text: $code)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))

                Button {
                    Task {
                        isWorking = true
                        let didAccept = await session.acceptInvite(code: code)
                        isWorking = false
                        if didAccept { dismiss() }
                    }
                } label: {
                    if isWorking {
                        ProgressView()
                    } else {
                        Text("Add Friend")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).count < 4 || isWorking)
            }

            if let error = session.lastError {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }

            Section {
                Text("Friends can see your shared location and status. Codes expire after 7 days.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Add Friend")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if session.activeInvite == nil {
                await session.createInvite()
            }
        }
    }
}
