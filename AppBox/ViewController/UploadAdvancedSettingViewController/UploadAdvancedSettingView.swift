//
//  UploadAdvancedSettingView.swift
//  AppBox

import SwiftUI
import AppKit

public final class AdvancedSettingsModel: NSObject, ObservableObject {
    @Published fileprivate var folderName: String
    let fieldEnabled: Bool

    public var onSave: (() -> Void)?
    public var onCancel: (() -> Void)?

    /// Bridge so the controller can read the field on save.
    public var folderNameText: String { folderName }

    public init(folderName: String, fieldEnabled: Bool) {
        self.folderName = folderName
        self.fieldEnabled = fieldEnabled
        super.init()
    }
}

struct UploadAdvancedSettingView: View {
    @ObservedObject var model: AdvancedSettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: IslandMetrics.sectionSpacing) {
            Text("Other Settings").font(IslandTypography.headline)

            VStack(alignment: .leading, spacing: 6) {
                LabeledField(label: "Custom Dropbox folder name",
                             prompt: "e.g. MyApp", text: $model.folderName)
                    .disabled(!model.fieldEnabled)
                if !model.fieldEnabled {
                    Text("Turn on “Keep the same link” to set a custom folder.")
                        .font(IslandTypography.caption).foregroundColor(.secondary)
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { model.onCancel?() }.keyboardShortcut(.cancelAction)
                Button("Save") { model.onSave?() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(IslandMetrics.padding)
        .frame(width: 440)
    }
}

public final class AdvancedSettingsHost: NSObject {
    public static func makeView(model: AdvancedSettingsModel) -> NSView {
        NSHostingView(rootView: UploadAdvancedSettingView(model: model).islandTypography())
    }
}
