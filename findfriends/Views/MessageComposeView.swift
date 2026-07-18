//
//  MessageComposeView.swift
//  findfriends
//

import SwiftUI
import MessageUI

struct MessageComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String?
    @Binding var isPresented: Bool

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        var parent: MessageComposeView

        init(_ parent: MessageComposeView) {
            self.parent = parent
        }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            parent.isPresented = false
        }
    }

    static var canSendText: Bool {
        MFMessageComposeViewController.canSendText()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.recipients = recipients
        controller.body = body
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
}

enum MessagesLauncher {
    /// Opens the Messages app addressed to the friend (iMessage when available).
    static func open(recipient: String) {
        let trimmed = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Prefer phone-style digits for sms:; keep emails as-is.
        let path: String
        if trimmed.contains("@") {
            path = trimmed
        } else {
            path = trimmed.filter { $0.isNumber || $0 == "+" }
        }
        guard !path.isEmpty, let url = URL(string: "sms:\(path)") else { return }
        UIApplication.shared.open(url)
    }
}
