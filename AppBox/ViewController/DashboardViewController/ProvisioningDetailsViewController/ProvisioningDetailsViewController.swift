//
//  ProvisioningDetailsViewController.swift
//  AppBox

import AppKit
import AppBoxCore

public final class ProvisioningDetailsViewController: NSViewController {

    public var uploadRecord: ABUploadRecord?

    public override func loadView() {
        guard let uploadRecord else {
            view = NSView()
            return
        }
        view = ProvisioningDetailsHost.makeView(record: uploadRecord, onClose: { [weak self] in
            self?.dismiss(nil)
        })
    }
}
