//
//  QRCodeViewController.swift
//  AppBox

import AppKit
import AppBoxCore

public final class QRCodeViewController: NSViewController {

    public var ipaUploadInfo: IPAUploadInfo?
    public var uploadRecord: ABUploadRecord?

    public override func loadView() {
        var url: String?
        if let ipaUploadInfo {
            url = ipaUploadInfo.appShortShareableURL?.absoluteString
        } else if let uploadRecord {
            url = uploadRecord.shortURL
        }

		if (url ?? "").isEmpty {
			url = "No URL found."
		}

        view = QRCodeHost.makeView(urlString: url ?? "", onClose: { [weak self] in
            self?.dismiss(nil)
        })
    }
}
