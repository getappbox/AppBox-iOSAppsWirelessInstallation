//
//  UploadAdvancedSettingViewController.swift
//  AppBox

import AppKit
import AppBoxCore

public protocol UploadAdvancedSettingViewDelegate: AnyObject {
    func uploadAdvancedSettingSaveButtonTapped(_ sender: NSButton?)
    func uploadAdvancedSettingCancelButtonTapped(_ sender: NSButton?)
}

public final class UploadAdvancedSettingViewController: NSViewController {

    public var ipaUploadInfo: IPAUploadInfo?
    public weak var delegate: UploadAdvancedSettingViewDelegate?

    private var model: AdvancedSettingsModel?
    private var initialFolder = ""

    public override func loadView() {
        initialFolder = RemotePath(path: ipaUploadInfo?.bundleDirectory?.absoluteString ?? "").relativePath
        let model = AdvancedSettingsModel(
			folderName: initialFolder,
			fieldEnabled: ipaUploadInfo?.isKeepSameLinkEnabled ?? false,
			placeholder: ipaUploadInfo?.identifer ?? "e.g. MyApp")
        self.model = model
        model.onSave = { [weak self] in self?.saveSettings() }
        model.onCancel = { [weak self] in self?.cancelSettings() }
        view = AdvancedSettingsHost.makeView(model: model)
    }

    // MARK: - Actions (invoked by the SwiftUI view's callbacks)

    private func cancelSettings() {
        dismiss(self)
        delegate?.uploadAdvancedSettingCancelButtonTapped(nil)
    }

    private func saveSettings() {
        let folder = (model?.folderNameText ?? "").trimmingCharacters(in: .whitespaces)
        if folder != initialFolder {
            if folder.isEmpty || folder == ipaUploadInfo?.identifer {
                ipaUploadInfo?.bundleDirectory = nil
            } else {
                ipaUploadInfo?.bundleDirectory = URL(string: "/\(folder)".replacingOccurrences(of: " ", with: ""))
            }
        }

        delegate?.uploadAdvancedSettingSaveButtonTapped(nil)
        dismiss(self)
    }
}
