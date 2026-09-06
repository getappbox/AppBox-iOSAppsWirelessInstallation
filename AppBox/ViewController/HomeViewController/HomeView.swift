//
//  HomeView.swift
//  AppBox

import SwiftUI
import AppKit
import UniformTypeIdentifiers

public final class HomeModel: NSObject, ObservableObject {
    @Published fileprivate(set) var fileName: String?
    @Published fileprivate(set) var isProcessing: Bool = false
    @Published fileprivate var emails: String = ""
    @Published fileprivate var message: String = ""
    @Published fileprivate var keepSameLink: Bool = false

    public var onChooseFile: (() -> Void)?
    public var onFileDropped: ((String) -> Void)?
    public var onUpload: (() -> Void)?
    public var onAdvanced: (() -> Void)?
    public var onSameLinkHelp: (() -> Void)?

    public var emailsText: String { get { emails } set { emails = newValue } }
    public var messageText: String { get { message } set { message = newValue } }
    public var keepSameLinkEnabled: Bool { get { keepSameLink } set { keepSameLink = newValue } }

    public func setFileName(_ name: String?) { fileName = name }
    public func setProcessing(_ processing: Bool) { isProcessing = processing }
}

struct HomeView: View {
    @ObservedObject var model: HomeModel
    @State private var isDropTargeted = false

    private var hasFile: Bool { model.fileName != nil }
    private var canUpload: Bool { hasFile && !model.isProcessing }

    var body: some View {
        ZStack {
            if hasFile {
                fileSelectedLayout
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                emptyLayout
                    .transition(.opacity)
            }
        }
        .frame(minWidth: 780, minHeight: 400)
        .animation(.easeInOut(duration: 0.3), value: hasFile)
    }

    // MARK: Empty state — a large drop zone fills the window
    private var emptyLayout: some View {
        bigDropZone.padding(IslandMetrics.padding)
    }

    // MARK: File selected — compact file header, then the options + actions appear
    private var fileSelectedLayout: some View {
        VStack(alignment: .leading, spacing: IslandMetrics.sectionSpacing) {
            fileHeader

            IslandSection("Send Email") {
                LabeledField(label: "Email Address",
                             prompt: "user@example.com, user2@example.com, …", text: $model.emails)
                LabeledField(label: "Personal Message",
                             prompt: "Add a personal message", text: $model.message)
            }

            HStack(spacing: 8) {
                Toggle("Keep the same link for this app", isOn: $model.keepSameLink)
                Button { model.onSameLinkHelp?() } label: { Image(systemName: "questionmark.circle") }
                    .buttonStyle(.borderless)
                    .help("Learn more")
                Spacer()
            }

            Spacer(minLength: 0)

            HStack {
                Button("Other Settings…") { model.onAdvanced?() }
                Spacer()
                Button("Upload IPA") { model.onUpload?() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!canUpload)
            }
        }
        .padding(IslandMetrics.padding)
        .disabled(model.isProcessing)
    }

    // MARK: Drop zones

	private var dropZoneShape: RoundedRectangle {
		RoundedRectangle(cornerRadius: 12)
	}

    private var bigDropZone: some View {
        Button { model.onChooseFile?() } label: {
            VStack(spacing: 14) {
                Image(systemName: "arrow.down.doc")
                    .font(IslandTypography.system(52, weight: .light))
                    .foregroundColor(.accentColor)
                VStack(spacing: 4) {
                    Text("Drop your .ipa here").font(IslandTypography.title3).fontWeight(.medium)
                    Text("or click to choose a file").foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                dropZoneShape
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [7]))
                    .foregroundColor(isDropTargeted ? .accentColor : .secondary.opacity(0.4))
            )
            .contentShape(dropZoneShape)
        }
        .buttonStyle(.plain)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { handleDrop($0) }
    }

    private var fileHeader: some View {
        Button { model.onChooseFile?() } label: {
            HStack(spacing: 12) {
                Image(systemName: "shippingbox.fill").font(IslandTypography.title2).foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Selected IPA").font(IslandTypography.caption).foregroundColor(.secondary)
                    Text(model.fileName ?? "").fontWeight(.medium).lineLimit(1)
                }
                Spacer()
                Text("Change").font(IslandTypography.callout).foregroundColor(.accentColor)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.25))
            )
        }
        .buttonStyle(.plain)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { handleDrop($0) }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard !model.isProcessing, let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            var url: URL?
            if let data = item as? Data { url = URL(dataRepresentation: data, relativeTo: nil) }
            else if let direct = item as? URL { url = direct }
            guard let url, url.pathExtension.lowercased() == "ipa" else { return }
            DispatchQueue.main.async { model.onFileDropped?(url.path) }
        }
        return true
    }
}

/// Wraps the SwiftUI view in an NSView for the controller to host.
public final class HomeHost: NSObject {
    public static func makeView(model: HomeModel) -> NSView {
        let host = NSHostingView(rootView: HomeView(model: model).islandTypography())
        host.sizingOptions = []
        return host
    }
}
