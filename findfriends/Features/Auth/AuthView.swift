//
//  AuthView.swift
//  findfriends
//

import SwiftUI

struct AuthView: View {
    @Environment(AppSession.self) private var session

    @State private var mode: Mode = .signIn
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var phoneNumber = ""
    @State private var isWorking = false

    private enum Mode {
        case signIn
        case signUp
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Mode", selection: $mode) {
                        Text("Sign In").tag(Mode.signIn)
                        Text("Create Account").tag(Mode.signUp)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }

                Section {
                    if mode == .signUp {
                        TextField("Display name", text: $displayName)
                            .textContentType(.name)
                        TextField("Phone number", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                    }
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                        .textContentType(mode == .signUp ? .newPassword : .password)
                } footer: {
                    Text(mode == .signUp
                          ? "Your phone number lets friends Message you in iMessage."
                          : "Sign in to load your saved profile.")
                }

                if let error = session.lastError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }

                Section {
                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            Spacer()
                            if isWorking {
                                ProgressView()
                            } else {
                                Text(mode == .signUp ? "Create Account" : "Sign In")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!canSubmit || isWorking)
                }
            }
            .navigationTitle("Find Friends")
            .tint(.green)
        }
    }

    private var canSubmit: Bool {
        let emailOK = email.contains("@")
        let passwordOK = password.count >= 6
        if mode == .signUp {
            let nameOK = !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let phoneOK = AccountUser.normalizedPhone(phoneNumber) != nil
            return emailOK && passwordOK && nameOK && phoneOK
        }
        return emailOK && passwordOK
    }

    private func submit() async {
        isWorking = true
        defer { isWorking = false }
        switch mode {
        case .signIn:
            await session.signIn(email: email, password: password)
        case .signUp:
            await session.signUp(
                email: email,
                password: password,
                displayName: displayName,
                phoneNumber: phoneNumber
            )
        }
    }
}
