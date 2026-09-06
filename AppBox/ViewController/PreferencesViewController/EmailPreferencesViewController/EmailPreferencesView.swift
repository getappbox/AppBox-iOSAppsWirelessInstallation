//
//  EmailPreferencesView.swift
//  AppBox

import SwiftUI
import AppBoxCore
import AppKit

public final class EmailModel: NSObject, ObservableObject {
    @Published fileprivate var emails: String
    @Published fileprivate var message: String
    @Published fileprivate(set) var isSendingTest: Bool = false

    public var onSave: (() -> Void)?
    public var onSendTest: (() -> Void)?

    public var emailsText: String { get { emails } set { emails = newValue } }
    public var messageText: String { get { message } set { message = newValue } }
    public func setSendingTest(_ sending: Bool) { isSendingTest = sending }

    public init(emails: String, message: String) {
        self.emails = emails
        self.message = message
        super.init()
    }
}

struct EmailPreferencesView: View {
    @ObservedObject var model: EmailModel

    var body: some View {
        VStack(alignment: .leading, spacing: IslandMetrics.sectionSpacing) {
            IslandSection("Email Notification") {
                LabeledField(label: "Recipient Emails", prompt: "Comma-separated email addresses", text: $model.emails)
                LabeledField(label: "Personal Message", prompt: "Optional message to include in the email", text: $model.message)
                IslandFootnote(lines: ["Included in the email under \"Message from the developer\"."])
            }
            HStack(spacing: 8) {
                if model.isSendingTest {
                    ProgressView().controlSize(.small)
                    Text("Sending…").foregroundColor(.secondary)
                } else {
                    Button("Send Test Mail") { model.onSendTest?() }
                }
                Spacer()
                Button("Save") { model.onSave?() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(model.isSendingTest)
            }
        }
        .padding(IslandMetrics.padding)
        .frame(width: IslandMetrics.paneWidth)
    }
}

public final class EmailPreferencesHost: NSObject {
    public static func makeView(model: EmailModel) -> NSView {
        NSHostingView(rootView: EmailPreferencesView(model: model).islandTypography())
    }
}
