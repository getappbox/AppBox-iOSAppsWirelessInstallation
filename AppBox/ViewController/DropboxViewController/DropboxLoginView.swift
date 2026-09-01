//
//  DropboxLoginView.swift
//  AppBox

import SwiftUI
import AppKit

struct DropboxLoginView: View {
    let quitTitle: String
    let onConnect: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox.fill")
                .font(IslandTypography.system(44))
                .foregroundColor(.accentColor)

            Text("Connect to Dropbox").font(IslandTypography.title3).fontWeight(.medium)

            Text("AppBox uploads your builds to Dropbox and only accesses its own app folder.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                Button("Connect to Dropbox", action: onConnect)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                Button(quitTitle, action: onQuit)
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(IslandMetrics.padding)
        .frame(width: 420)
    }
}

public final class DropboxLoginHost: NSObject {
    public static func makeView(
		quitTitle: String,
		onConnect: @escaping () -> Void,
		onQuit: @escaping () -> Void) -> NSView {
			let dbLoginView = DropboxLoginView(
				quitTitle: quitTitle,
				onConnect: onConnect,
				onQuit: onQuit).islandTypography()
			return NSHostingView(rootView: dbLoginView)
		}
}
