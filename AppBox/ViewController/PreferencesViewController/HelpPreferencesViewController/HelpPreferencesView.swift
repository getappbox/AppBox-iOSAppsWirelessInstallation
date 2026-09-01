//
//  HelpPreferencesView.swift
//  AppBox

import SwiftUI
import AppKit

struct HelpPreferencesView: View {
    let documentationURL: String
    let cliURL: String
    let releasesURL: String
    let licenseURL: String

    var body: some View {
        VStack(alignment: .leading, spacing: IslandMetrics.sectionSpacing) {
            header

            IslandSection("Help & Documentation") {
                linkRow("Documentation", subtitle: "Guides and feature references",
                        systemImage: "book", urlString: documentationURL)
                Divider()
                linkRow("Command-Line Interface", subtitle: "Automate uploads from your terminal",
                        systemImage: "terminal", urlString: cliURL)
            }

            IslandSection("About AppBox") {
                linkRow("What's New", subtitle: "Latest release notes on GitHub",
                        systemImage: "sparkles", urlString: releasesURL)
                Divider()
                linkRow("License", subtitle: "Open-source license",
                        systemImage: "doc.text", urlString: licenseURL)
            }
        }
        .padding(IslandMetrics.padding)
        .frame(width: IslandMetrics.paneWidth)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text("AppBox").font(IslandTypography.title2).bold()
                Text(versionString).font(IslandTypography.subheadline).foregroundColor(.secondary)
                Text("Build, test and distribute iOS apps wirelessly.")
                    .font(IslandTypography.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "Version \(short) (\(build))"
    }

    private func linkRow(_ title: String, subtitle: String, systemImage: String, urlString: String) -> some View {
        Button {
            if let url = URL(string: urlString) { NSWorkspace.shared.open(url) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(IslandTypography.system(15))
                    .foregroundColor(.accentColor)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).foregroundColor(.primary)
                    Text(subtitle).font(IslandTypography.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right").font(IslandTypography.caption).foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
}

public final class HelpPreferencesHost: NSObject {
    public static func makeView(documentationURL: String, cliURL: String,
                                releasesURL: String, licenseURL: String) -> NSView {
        NSHostingView(rootView: HelpPreferencesView(
            documentationURL: documentationURL, cliURL: cliURL,
            releasesURL: releasesURL, licenseURL: licenseURL).islandTypography())
    }
}
