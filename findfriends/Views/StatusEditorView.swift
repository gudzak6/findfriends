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
    @Bindable var profile: UserProfile

    @State private var customStatus = ""
    @State private var selectedEmoji = ""

    private let presets: [StatusPreset] = [
        StatusPreset(emoji: "☕️", label: "Getting coffee"),
        StatusPreset(emoji: "🍕", label: "Getting food"),
        StatusPreset(emoji: "💪", label: "At the gym"),
        StatusPreset(emoji: "🏃", label: "On a run"),
        StatusPreset(emoji: "📚", label: "Studying"),
        StatusPreset(emoji: "🎬", label: "At the movies"),
        StatusPreset(emoji: "🛒", label: "Shopping"),
        StatusPreset(emoji: "🏠", label: "At home"),
        StatusPreset(emoji: "🚗", label: "Driving"),
        StatusPreset(emoji: "✈️", label: "Traveling"),
        StatusPreset(emoji: "💼", label: "At work"),
        StatusPreset(emoji: "🎉", label: "Out with friends"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Status") {
                    HStack {
                        TextField("Emoji", text: $selectedEmoji)
                            .frame(width: 44)
                            .multilineTextAlignment(.center)
                            .font(.title2)

                        TextField("What are you doing?", text: $customStatus)
                    }

                    if !customStatus.isEmpty || !selectedEmoji.isEmpty {
                        Button("Clear Status", role: .destructive) {
                            clearStatus()
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveStatus()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                customStatus = profile.status ?? ""
                selectedEmoji = profile.statusEmoji ?? ""
            }
        }
    }

    private func saveStatus() {
        let trimmed = customStatus.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            profile.status = nil
            profile.statusEmoji = nil
            profile.statusUpdatedAt = nil
        } else {
            profile.status = trimmed
            profile.statusEmoji = selectedEmoji.isEmpty ? nil : selectedEmoji
            profile.statusUpdatedAt = Date()
        }
    }

    private func clearStatus() {
        customStatus = ""
        selectedEmoji = ""
        profile.status = nil
        profile.statusEmoji = nil
        profile.statusUpdatedAt = nil
    }
}
