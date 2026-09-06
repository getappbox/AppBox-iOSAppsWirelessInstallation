//
//  AccountPreferencesView.swift
//  AppBox

import SwiftUI
import AppKit

public final class AccountsModel: NSObject, ObservableObject {
    @Published fileprivate(set) var isConnected: Bool = false
    @Published fileprivate(set) var displayName: String = ""
    @Published fileprivate(set) var email: String = ""
    @Published fileprivate(set) var usedSpaceMB: Int = 0
    @Published fileprivate(set) var totalSpaceMB: Int = 0

    public var onConnect: (() -> Void)?
    public var onDisconnect: (() -> Void)?

    public func update(connected: Bool, displayName: String, email: String,
                             usedSpaceMB: Int, totalSpaceMB: Int) {
        self.isConnected = connected
        self.displayName = displayName
        self.email = email
        self.usedSpaceMB = usedSpaceMB
        self.totalSpaceMB = totalSpaceMB
    }
}

struct AccountPreferencesView: View {
    @ObservedObject var model: AccountsModel

    var body: some View {
        VStack(alignment: .leading, spacing: IslandMetrics.sectionSpacing) {
            IslandSection("Dropbox") {
                if model.isConnected {
                    connectedContent
                } else {
                    HStack {
                        Text("No Dropbox account connected.").foregroundColor(.secondary)
                        Spacer()
                        Button("Connect…") { model.onConnect?() }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(IslandMetrics.padding)
        .frame(width: IslandMetrics.paneWidth,
               height: IslandMetrics.accountPaneHeight,
               alignment: .topLeading)
    }

    private var connectedContent: some View {
        VStack(alignment: .leading, spacing: IslandMetrics.fieldSpacing) {
            HStack(spacing: 12) {
                Image(systemName: "shippingbox.fill").font(IslandTypography.title).foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.displayName.isEmpty ? "Dropbox account" : model.displayName)
                        .fontWeight(.medium)
                    if !model.email.isEmpty {
                        Text(model.email).font(IslandTypography.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button("Disconnect") { model.onDisconnect?() }
            }

            if model.totalSpaceMB > 0 {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Storage").font(IslandTypography.caption).foregroundColor(.secondary)
                        Spacer()
                        Text("\(formatSpace(model.usedSpaceMB)) of \(formatSpace(model.totalSpaceMB)) used")
                            .font(IslandTypography.caption).foregroundColor(.secondary)
                    }
                    ProgressView(value: usedFraction)
                }
            }
        }
    }

    private var usedFraction: Double {
        guard model.totalSpaceMB > 0 else { return 0 }
        return min(1, Double(model.usedSpaceMB) / Double(model.totalSpaceMB))
    }

    private func formatSpace(_ mb: Int) -> String {
        let value = Double(mb)
        if value >= 1_048_576 { return String(format: "%.2f TB", value / 1_048_576) }
        if value >= 1024 { return String(format: "%.1f GB", value / 1024) }
        return "\(mb) MB"
    }
}

public final class AccountsHost: NSObject {
    public static func makeView(model: AccountsModel) -> NSView {
        NSHostingView(rootView: AccountPreferencesView(model: model).islandTypography())
    }
}
