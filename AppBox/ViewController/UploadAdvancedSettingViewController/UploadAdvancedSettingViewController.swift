//
//  UploadAdvancedSettingViewController.swift
//  AppBox

import AppKit

public protocol UploadAdvancedSettingViewDelegate: AnyObject {
    func uploadAdvancedSettingSaveButtonTapped(_ sender: NSButton?)
    func uploadAdvancedSettingCancelButtonTapped(_ sender: NSButton?)
}

public final class UploadAdvancedSettingViewController: NSViewController {

    public var ipaUploadInfo: IPAUploadInfo?
    public weak var delegate: UploadAdvancedSettingViewDelegate?

    private var model: AdvancedSettingsModel?

    public override func loadView() {
        let folder = ipaUploadInfo?.bundleDirectory?.lastPathComponent ?? ""
        let model = AdvancedSettingsModel(folderName: folder,
                                          fieldEnabled: ipaUploadInfo?.isKeepSameLinkEnabled ?? false)
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
        delegate?.uploadAdvancedSettingSaveButtonTapped(nil)

        if let folder = model?.folderNameText, folder != ipaUploadInfo?.identifer, !folder.isEmpty {
            let bundlePath = "/\(folder)".replacingOccurrences(of: " ", with: "")
            ipaUploadInfo?.bundleDirectory = URL(string: bundlePath)
        }

        dismiss(self)
    }
}
