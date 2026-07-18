//
//  StatusEditorView.swift
//  findfriends
//

import SwiftUI

struct StatusPreset: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
    let label: String
}

struct StatusEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var session

    let account: AccountUser

    @State private var customStatus = ""
    @State private var selectedEmoji = ""
    @State private var duration: StatusDuration = .oneHour

    private let presets: [StatusPreset] = [
        StatusPreset(emoji: "☕️", label: "Down for coffee"),
        StatusPreset(emoji: "🎧", label: "Heads down"),
        StatusPreset(emoji: "💪", label: "At the gym"),
        StatusPreset(emoji: "🏃", label: "On a run"),
        StatusPreset(emoji: "📚", label: "Studying"),
        StatusPreset(emoji: "🍕", label: "Getting food"),
        StatusPreset(emoji: "🚗", label: "Driving"),
        StatusPreset(emoji: "✈️", label: "Traveling"),
        StatusPreset(emoji: "💼", label: "At work"),
        StatusPreset(emoji: "🏠", label: "At home"),
        StatusPreset(emoji: "🎉", label: "Out with friends"),
        StatusPreset(emoji: "💬", label: "Free to chat"),
    ]

    var body: some View {
        Form {
            Section("Your Status") {
                HStack {
                    TextField("Emoji", text: $selectedEmoji)
                        .frame(width: 44)
                        .multilineTextAlignment(.center)
                        .font(.title2)

                    TextField("What are you up to?", text: $customStatus)
                }

                Picker("Expires", selection: $duration) {
                    ForEach(StatusDuration.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }

                if !customStatus.isEmpty || account.status.text != nil {
                    Button("Clear Status", role: .destructive) {
                        session.setStatus(text: nil, emoji: nil, duration: .untilCleared)
                        dismiss()
                    }
                }
            }

            Section("Quick Pick") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                    ForEach(presets) { preset in
                        Button {
                            selectedEmoji = preset.emoji
                            customStatus = preset.label
                        } label: {
                            HStack(spacing: 8) {
                                Text(preset.emoji)
                                    .font(.title3)
                                Text(preset.label)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Set Status")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    session.setStatus(
                        text: customStatus,
                        emoji: selectedEmoji,
                        duration: duration
                    )
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            customStatus = account.status.text ?? ""
            selectedEmoji = account.status.emoji ?? ""
        }
    }
}
