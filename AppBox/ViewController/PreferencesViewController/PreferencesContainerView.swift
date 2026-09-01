//
//  PreferencesContainerView.swift
//  AppBox

import SwiftUI
import AppKit

/// One preferences entry: a sidebar title + SF Symbol + tile tint, plus the pane's AppKit content view and its fitting size (measured by the host) so the SwiftUI layout sizes deterministically.
public final class PreferencePane: NSObject {
    public let title: String
    public let systemImage: String
    public let tint: NSColor
    public let view: NSView
    public let preferredSize: CGSize

    public init(title: String, systemImage: String, tint: NSColor,
                      view: NSView, preferredSize: CGSize) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.view = view
        self.preferredSize = preferredSize
        super.init()
    }
}

/// Hosts a pane's existing AppKit view inside the SwiftUI detail column.
private struct PaneRepresentable: NSViewRepresentable {
    let nsView: NSView
    func makeNSView(context: Context) -> NSView { nsView }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct PreferencesContainerView: View {
    let panes: [PreferencePane]
    @State private var selection: Int? = 0

    private var detailWidth: CGFloat { panes.map { $0.preferredSize.width }.max() ?? 600 }
    private var detailHeight: CGFloat { max(panes.map { $0.preferredSize.height }.max() ?? 400, 360) }

    var body: some View {
        NavigationView {
            List(selection: $selection) {
                ForEach(panes.indices, id: \.self) { index in
                    sidebarRow(panes[index]).tag(index)
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 235, idealWidth: 250, maxWidth: 280)

            detail
        }
        .frame(width: 250 + detailWidth + 16, height: detailHeight)
    }

    /// An Xcode/System-Settings-style row: a rounded colored tile holding a white glyph, then the title.
    private func sidebarRow(_ pane: PreferencePane) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color(nsColor: pane.tint))
                .frame(width: 20, height: 20)
                .overlay(
                    Image(systemName: pane.systemImage)
                        .font(IslandTypography.system(12, weight: .semibold))
                        .foregroundColor(.white)
                )
            Text(pane.title).font(IslandTypography.body)
        }
        .padding(.vertical, 3)
    }

    @ViewBuilder private var detail: some View {
        if let selection, panes.indices.contains(selection) {
            let pane = panes[selection]
            VStack(alignment: .leading, spacing: 0) {
                PaneRepresentable(nsView: pane.view)
                    .frame(width: pane.preferredSize.width, height: pane.preferredSize.height)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .id(selection) // force the representable to re-host the selected pane's view
        } else {
            Color.clear
        }
    }
}

/// Builds the SwiftUI container view from the assembled panes.
public final class PreferencesContainerHost: NSObject {
    public static func makeView(panes: [PreferencePane]) -> NSView {
        NSHostingView(rootView: PreferencesContainerView(panes: panes).islandTypography())
    }
}
