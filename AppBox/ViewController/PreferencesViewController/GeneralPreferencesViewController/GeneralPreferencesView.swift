//
//  GeneralPreferencesView.swift
//  AppBox

import SwiftUI
import AppKit

struct GeneralPreferencesView: View {
    let chunkSizes: [Int]
    let helpURLs: [String: String]
    let onChunkSize: (Int) -> Void
    let onBoolChange: (String, Bool) -> Void
    let onSetDefaultHandler: (Bool) -> Void
    let onToggleCLI: () -> Bool

    @State private var chunkSize: Int
    @State private var downloadIPA: Bool
    @State private var moreDetails: Bool
    @State private var hidePreviousVersions: Bool
    @State private var updateAlert: Bool
    @State private var limitedLog: Bool
    @State private var isDefaultHandler: Bool
    @State private var cliInstalled: Bool

    init(chunkSize: Int, chunkSizes: [Int], downloadIPA: Bool, moreDetails: Bool,
         hidePreviousVersions: Bool, updateAlert: Bool, limitedLog: Bool, isDefaultHandler: Bool,
         cliInstalled: Bool, helpURLs: [String: String],
         onChunkSize: @escaping (Int) -> Void,
         onBoolChange: @escaping (String, Bool) -> Void,
         onSetDefaultHandler: @escaping (Bool) -> Void,
         onToggleCLI: @escaping () -> Bool) {
        self.chunkSizes = chunkSizes
        self.helpURLs = helpURLs
        self.onChunkSize = onChunkSize
        self.onBoolChange = onBoolChange
        self.onSetDefaultHandler = onSetDefaultHandler
        self.onToggleCLI = onToggleCLI
        _chunkSize = State(initialValue: chunkSize)
        _downloadIPA = State(initialValue: downloadIPA)
        _moreDetails = State(initialValue: moreDetails)
        _hidePreviousVersions = State(initialValue: hidePreviousVersions)
        _updateAlert = State(initialValue: updateAlert)
        _limitedLog = State(initialValue: limitedLog)
        _isDefaultHandler = State(initialValue: isDefaultHandler)
        _cliInstalled = State(initialValue: cliInstalled)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IslandMetrics.sectionSpacing) {
            IslandSection("Upload") {
                HStack {
                    Text("Upload chunk size (MB)")
                    Spacer()
                    Picker("", selection: chunkBinding) {
                        ForEach(chunkSizes, id: \.self) { Text("\($0)").font(IslandTypography.body).tag($0) }
                    }
                    .labelsHidden()
                    .frame(width: 90)
                    HelpLinkButton(urlString: helpURLs["chunkSize"])
                }
                toggleRow("Include a download-IPA link", key: "downloadIPA", value: $downloadIPA)
                toggleRow("Include more build details", key: "moreDetails", value: $moreDetails)
                toggleRow("Don't show previous versions on the install page", key: "hidePreviousVersions", value: $hidePreviousVersions)
            }

            IslandSection("General") {
                toggleRow("Check for updates", key: "updateAlert", value: $updateAlert)
                toggleRow("Limited logging", key: "limitedLog", value: $limitedLog)
                Toggle("Set AppBox as the default handler for .ipa files", isOn: Binding(
                    get: { isDefaultHandler },
                    set: { isDefaultHandler = $0; onSetDefaultHandler($0) }))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            IslandSection("Command-Line Tool") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cliInstalled ? "Installed at /usr/local/bin/appboxcli" : "Not installed")
                        Text("Upload builds from your terminal or CI.")
                            .font(IslandTypography.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(cliInstalled ? "Uninstall" : "Install") { cliInstalled = onToggleCLI() }
                    HelpLinkButton(urlString: helpURLs["cli"])
                }
            }
        }
        .padding(IslandMetrics.padding)
        .frame(width: IslandMetrics.paneWidth)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ABDefaultIPAHandlerDidChangeNotification"))) { note in
            if let isDefault = note.userInfo?["isDefault"] as? Bool {
                isDefaultHandler = isDefault
            }
        }
    }

    private var chunkBinding: Binding<Int> {
        Binding(get: { chunkSize }, set: { chunkSize = $0; onChunkSize($0) })
    }

    private func toggleRow(_ label: String, key: String, value: Binding<Bool>) -> some View {
        HStack {
            Toggle(label, isOn: Binding(get: { value.wrappedValue },
                                        set: { value.wrappedValue = $0; onBoolChange(key, $0) }))
            Spacer()
            HelpLinkButton(urlString: helpURLs[key])
        }
    }
}

public final class GeneralPreferencesHost: NSObject {
    public static func makeView(chunkSize: Int, chunkSizes: [Int],
                                downloadIPA: Bool, moreDetails: Bool, hidePreviousVersions: Bool,
                                updateAlert: Bool, limitedLog: Bool, isDefaultHandler: Bool,
                                cliInstalled: Bool, helpURLs: [String: String],
                                onChunkSize: @escaping (Int) -> Void,
                                onBoolChange: @escaping (String, Bool) -> Void,
                                onSetDefaultHandler: @escaping (Bool) -> Void,
                                onToggleCLI: @escaping () -> Bool) -> NSView {
        NSHostingView(rootView: GeneralPreferencesView(
            chunkSize: chunkSize, chunkSizes: chunkSizes,
            downloadIPA: downloadIPA, moreDetails: moreDetails, hidePreviousVersions: hidePreviousVersions,
            updateAlert: updateAlert, limitedLog: limitedLog, isDefaultHandler: isDefaultHandler,
            cliInstalled: cliInstalled, helpURLs: helpURLs,
            onChunkSize: onChunkSize, onBoolChange: onBoolChange, onSetDefaultHandler: onSetDefaultHandler,
            onToggleCLI: onToggleCLI).islandTypography())
    }
}
