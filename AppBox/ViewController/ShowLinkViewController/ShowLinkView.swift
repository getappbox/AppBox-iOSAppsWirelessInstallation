//
//  ShowLinkView.swift
//  AppBox

import SwiftUI
import AppKit

struct ShowLinkView: View {
    let link: String
    let isLongURL: Bool
    let onShowQR: () -> Void
    let onShowDashboard: () -> Void
    let onClose: () -> Void

    @State private var copied = false

    private var hint: String {
        isLongURL
            ? "Your app is ready. Copy this link and share it with anyone. (Our URL shortener is temporarily unavailable, so this is the full link.)"
            : "Your app is ready. Copy this link and share it with anyone."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IslandMetrics.sectionSpacing) {
            Text("Your link is ready").font(IslandTypography.headline)

            Text(hint)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(link)
				.font(IslandTypography.headline.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .textBackgroundColor)))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color(nsColor: .separatorColor)))

            HStack(spacing: 10) {
                Button(copied ? "Copied!" : "Copy", action: copyLink)
                Button("Open", action: openLink).keyboardShortcut(.defaultAction)
                Button("QR Code", action: onShowQR)
                Button("Show in Dashboard", action: onShowDashboard)
                Spacer()
                Button("Close", action: onClose).keyboardShortcut(.cancelAction)
            }
        }
        .padding(IslandMetrics.padding)
        .frame(width: 560)
    }

    private func copyLink() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(link, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { copied = false }
    }

    private func openLink() {
        guard let url = URL(string: link) else { return }
        NSWorkspace.shared.open(url)
    }
}

public final class ShowLinkHost: NSObject {
    public static func makeView(
		link: String,
		isLongURL: Bool,
		onShowQR: @escaping () -> Void,
		onShowDashboard: @escaping () -> Void,
		onClose: @escaping () -> Void) -> NSView {
			let showLinkView = ShowLinkView(
				link: link,
				isLongURL: isLongURL,
				onShowQR: onShowQR,
				onShowDashboard: onShowDashboard,
				onClose: onClose).islandTypography()
			return NSHostingView(rootView: showLinkView)
    }
}
