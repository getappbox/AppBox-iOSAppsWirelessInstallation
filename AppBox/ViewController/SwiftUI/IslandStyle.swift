//
//  IslandStyle.swift
//  AppBox

import SwiftUI
import AppKit

enum IslandMetrics {
    static let padding: CGFloat = 24
    static let sectionSpacing: CGFloat = 20
    static let fieldSpacing: CGFloat = 12

    static let qrWidth: CGFloat = 320
    static let sheetWidth: CGFloat = 540
    static let paneWidth: CGFloat = 660

    static let accountPaneHeight: CGFloat = 320
}

/// The app's type scale. Every text style derives from `scale`, so the whole UI resizes from one number.
enum IslandTypography {
    static let scale: CGFloat = 1.2

    /// The macOS system size for a text style, scaled and rounded to a whole point.
	static func size(_ base: CGFloat) -> CGFloat {
		(base * scale).rounded()
	}

    static let caption = Font.system(size: size(10))
    static let subheadline = Font.system(size: size(11))
    static let callout = Font.system(size: size(12))
    static let body = Font.system(size: size(13))
    static let headline = Font.system(size: size(13), weight: .semibold)
    static let title3 = Font.system(size: size(15))
    static let title2 = Font.system(size: size(17))
    static let title = Font.system(size: size(22))

    static func system(_ base: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size(base), weight: weight)
    }
}

extension View {
    /// Applies the app's type scale as the default font for a hosted SwiftUI root.
    func islandTypography() -> some View {
        environment(\.font, IslandTypography.body)
            .controlSize(.large)
    }
}

/// A caption label above a rounded-border text field — the standard island form field.
struct LabeledField: View {
    let label: String
    let prompt: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(IslandTypography.subheadline).foregroundColor(.secondary)
            TextField(prompt, text: $text)
                .textFieldStyle(.roundedBorder)
                .controlSize(.large)
        }
    }
}

/// A titled card section (GroupBox) with consistent header + inner spacing.
struct IslandSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(IslandTypography.headline)
                .padding(.leading, 2)
            GroupBox {
                VStack(alignment: .leading, spacing: IslandMetrics.fieldSpacing) {
                    content()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
            }
        }
    }
}

/// A caption-sized note under a field: an optional title above a list of lines.
struct IslandFootnote: View {
    let title: String?
    let lines: [String]

    init(_ title: String? = nil, lines: [String]) {
        self.title = title
        self.lines = lines
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let title {
                Text(title)
                    .font(IslandTypography.caption)
                    .foregroundColor(.secondary)
            }
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(IslandTypography.caption)
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A small inline "?" help button that opens a URL.
struct HelpLinkButton: View {
    let urlString: String?

    var body: some View {
        if let urlString, let url = URL(string: urlString) {
            Button { NSWorkspace.shared.open(url) } label: {
                Image(systemName: "questionmark.circle")
            }
            .buttonStyle(.borderless)
            .help("Learn more")
        }
    }
}
