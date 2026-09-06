//
//  DashboardView.swift
//  AppBox

import SwiftUI
import AppKit

/// A build history entry, flattened to display strings by the host.
public final class BuildRow: NSObject {
    public let recordIndex: Int
    public let name: String
    public let bundleId: String
    public let versionBuild: String
    public let shortURL: String
    public let date: String
    public let buildType: String
    public let team: String

    public init(recordIndex: Int, name: String, bundleId: String, versionBuild: String, shortURL: String,
                date: String, buildType: String, team: String) {
        self.recordIndex = recordIndex
        self.name = name
        self.bundleId = bundleId
        self.versionBuild = versionBuild
        self.shortURL = shortURL
        self.date = date
        self.buildType = buildType
        self.team = team
        super.init()
    }
}

/// Bridges the build list + actions between the controller and the SwiftUI view.
public final class DashboardModel: NSObject, ObservableObject {
    @Published fileprivate(set) var builds: [BuildRow] = []
    @Published fileprivate(set) var requestedShortURL: String?

    public var onCopyURL: ((Int) -> Void)?
    public var onOpenURL: ((Int) -> Void)?
    public var onShowQR: ((Int) -> Void)?
    public var onProvisioning: ((Int) -> Void)?
    public var onShowInFinder: ((Int) -> Void)?
    public var onShowInDropbox: ((Int) -> Void)?
    public var onDelete: ((Int) -> Void)?

    public func setBuilds(_ newBuilds: [BuildRow]) {
        builds = newBuilds
    }

    public func requestSelection(shortURL: String?) {
        requestedShortURL = shortURL
    }

    /// Distinct app names, sorted alphabetically (case-insensitive) for stable, predictable ordering — so deleting a build never reshuffles the app list by upload date.
    static func orderedApps(_ builds: [BuildRow]) -> [String] {
        var seen = Set<String>()
        var names: [String] = []
        for build in builds where !seen.contains(build.name) {
            seen.insert(build.name)
            names.append(build.name)
        }
        return names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}

struct DashboardView: View {
    @ObservedObject var model: DashboardModel
    // @Published ("publishing changes from within view updates").
    @State private var selectedAppName: String?
    @State private var selection: Int?

    private var apps: [String] { DashboardModel.orderedApps(model.builds) }

    private var effectiveApp: String? {
        if let selectedAppName, apps.contains(selectedAppName) { return selectedAppName }
        return model.builds.first?.name ?? apps.first
    }

	/// The selected app's builds (newest first, as delivered by the controller).
    private var appBuilds: [BuildRow] { model.builds.filter { $0.name == effectiveApp } }

    /// The build to show within the app: the user's pick while it still exists, else the app's newest build.
    private var effectiveSelection: Int? {
        if let selection, appBuilds.contains(where: { $0.recordIndex == selection }) {
            return selection
        }
        return appBuilds.first?.recordIndex
    }
    private var selectedBuild: BuildRow? {
        guard let index = effectiveSelection else { return nil }
        return appBuilds.first { $0.recordIndex == index }
    }

    private var listSelection: Binding<Int?> {
        Binding(get: { effectiveSelection }, set: { selection = $0 })
    }

    var body: some View {
        NavigationView {
            sidebar
            detail
        }
        .frame(minWidth: 780, idealWidth: 940, minHeight: 460, idealHeight: 600)
        .onChange(of: model.requestedShortURL, initial: true) { _, _ in
            selectRequestedBuild()
        }
    }

    private func selectRequestedBuild() {
        guard let shortURL = model.requestedShortURL, !shortURL.isEmpty,
              let build = model.builds.first(where: { $0.shortURL == shortURL }) else { return }
        selectedAppName = build.name
        selection = build.recordIndex
        model.requestSelection(shortURL: nil)
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            if !apps.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("App").font(IslandTypography.caption).foregroundColor(.secondary)
                    Picker("", selection: appPickerBinding) {
                        ForEach(apps, id: \.self) { Text($0).font(IslandTypography.body).tag(Optional($0)) }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }
                .padding(12)
                Divider()
            }

            List(selection: listSelection) {
                ForEach(appBuilds, id: \.recordIndex) { build in
                    buildRow(build).tag(build.recordIndex)
                }
            }
            .listStyle(.sidebar)
            .onKeyPress(.return) {
                guard let index = effectiveSelection else { return .ignored }
                model.onOpenURL?(index)
                return .handled
            }
            .onDeleteCommand {
                if let index = effectiveSelection { model.onDelete?(index) }
            }
        }
        .frame(minWidth: 250, idealWidth: 285, maxWidth: 340)
    }

    /// Picking an app selects it by name and resets the build pick so it re-derives to that app's newest build.
    private var appPickerBinding: Binding<String?> {
        Binding(
            get: { effectiveApp },
            set: { newApp in
                selectedAppName = newApp
                selection = nil
            }
        )
    }

    private func buildRow(_ build: BuildRow) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "shippingbox.fill")
                .font(IslandTypography.title3).foregroundColor(.accentColor).frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(build.versionBuild).font(IslandTypography.body).fontWeight(.medium).lineLimit(1)
                Text(build.date).font(IslandTypography.caption).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: Detail

    @ViewBuilder private var detail: some View {
        if let build = selectedBuild {
            buildDetail(build)
        } else {
            emptyState
        }
    }

    private func buildDetail(_ build: BuildRow) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: IslandMetrics.sectionSpacing) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(build.name).font(IslandTypography.title2).bold()
                    Text(build.versionBuild).font(IslandTypography.subheadline).foregroundColor(.secondary)
                }

                IslandSection("Build details") {
                    detailRow("Bundle ID", build.bundleId)
                    detailRow("Version", build.versionBuild)
                    detailRow("Build type", build.buildType)
                    detailRow("Team", build.team)
                    detailRow("Uploaded", build.date)
                    detailRow("Short URL", build.shortURL)
                }

                actions(recordIndex: build.recordIndex)
            }
            .padding(IslandMetrics.padding)
            .frame(maxWidth: 620, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func actions(recordIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Actions").font(IslandTypography.headline)
            HStack(spacing: 10) {
                actionButton("Open", "safari") { model.onOpenURL?(recordIndex) }
                actionButton("Copy Link", "doc.on.doc") { model.onCopyURL?(recordIndex) }
                actionButton("QR Code", "qrcode") { model.onShowQR?(recordIndex) }
            }
            HStack(spacing: 10) {
                actionButton("Provisioning", "checkmark.seal") { model.onProvisioning?(recordIndex) }
                actionButton("Show in Finder", "folder") { model.onShowInFinder?(recordIndex) }
                actionButton("Show in Dropbox", "shippingbox") { model.onShowInDropbox?(recordIndex) }
            }
            Divider().padding(.vertical, 4)
            Button(role: .destructive) { model.onDelete?(recordIndex) } label: {
                Label("Delete Build", systemImage: "trash")
            }
        }
    }

    private func actionButton(_ title: String, _ systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Label(title, systemImage: systemImage) }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label).font(IslandTypography.caption).foregroundColor(.secondary).frame(width: 96, alignment: .leading)
            Text(value.isEmpty ? "—" : value).textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox").font(IslandTypography.system(46)).foregroundColor(.secondary)
            Text("No builds yet").font(IslandTypography.title3)
            Text("Builds you upload will appear here.").foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Wraps the SwiftUI view in an NSView for the controller to host.
public final class DashboardHost: NSObject {
    public static func makeView(model: DashboardModel) -> NSView {
        let host = NSHostingView(rootView: DashboardView(model: model).islandTypography())
        host.sizingOptions = []
        return host
    }
}
