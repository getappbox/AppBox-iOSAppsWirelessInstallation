//
//  ThirdPartyPreferencesView.swift
//  AppBox

import SwiftUI
import AppBoxCore
import AppKit

public final class ThirdPartyModel: NSObject, ObservableObject {
    @Published fileprivate var slackWebhook: String
    @Published fileprivate var teamsWebhook: String
    @Published fileprivate(set) var isTestingSlack: Bool = false
    @Published fileprivate(set) var isTestingTeams: Bool = false

    public var onSave: (() -> Void)?
    public var onTestSlack: (() -> Void)?
    public var onTestTeams: (() -> Void)?
    public var onSetupWebhook: (() -> Void)?

    public var slackWebhookText: String { get { slackWebhook } set { slackWebhook = newValue } }
    public var teamsWebhookText: String { get { teamsWebhook } set { teamsWebhook = newValue } }
    public func setTestingSlack(_ testing: Bool) { isTestingSlack = testing }
    public func setTestingTeams(_ testing: Bool) { isTestingTeams = testing }

    public init(slackWebhook: String, teamsWebhook: String) {
        self.slackWebhook = slackWebhook
        self.teamsWebhook = teamsWebhook
        super.init()
    }
}

struct ThirdPartyPreferencesView: View {
    @ObservedObject var model: ThirdPartyModel

    var body: some View {
        VStack(alignment: .leading, spacing: IslandMetrics.sectionSpacing) {
            IslandSection("Slack") {
                LabeledField(label: "Incoming Webhook URL", prompt: "https://hooks.slack.com/services/…", text: $model.slackWebhook)
                HStack(spacing: 8) {
                    if model.isTestingSlack {
                        ProgressView().controlSize(.small)
                        Text("Sending…").foregroundColor(.secondary)
                    } else {
                        Button("Test Slack") { model.onTestSlack?() }
                        Button("Set up a webhook…") { model.onSetupWebhook?() }.buttonStyle(.link)
                    }
                    Spacer()
                }
            }

            IslandSection("Microsoft Teams") {
                LabeledField(label: "Incoming Webhook URL", prompt: "https://outlook.office.com/webhook/…", text: $model.teamsWebhook)
                HStack(spacing: 8) {
                    if model.isTestingTeams {
                        ProgressView().controlSize(.small)
                        Text("Sending…").foregroundColor(.secondary)
                    } else {
                        Button("Test Teams") { model.onTestTeams?() }
                    }
                    Spacer()
                }
            }

            HStack {
                Spacer()
                Button("Save") { model.onSave?() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(model.isTestingSlack || model.isTestingTeams)
            }
        }
        .padding(IslandMetrics.padding)
        .frame(width: IslandMetrics.paneWidth)
    }
}

public final class ThirdPartyPreferencesHost: NSObject {
    public static func makeView(model: ThirdPartyModel) -> NSView {
        NSHostingView(rootView: ThirdPartyPreferencesView(model: model).islandTypography())
    }
}
