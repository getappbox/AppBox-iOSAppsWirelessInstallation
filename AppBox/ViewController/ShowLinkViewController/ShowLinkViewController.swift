//
//  ShowLinkViewController.swift
//  AppBox

import AppKit
import AppBoxCore

public final class ShowLinkViewController: NSViewController {

    public var ipaUploadInfo: IPAUploadInfo?

	public override func loadView() {
		let link = ipaUploadInfo?.appShortShareableURL?.absoluteString ?? ""
		let isLongURL = ipaUploadInfo?.appShortShareableURL == ipaUploadInfo?.appLongShareableURL
		view = ShowLinkHost.makeView(
			link: link,
			isLongURL: isLongURL,
			onShowQR: { [weak self] in
				self?.presentQRCodeSheet()
			},
			onShowDashboard: { [weak self] in
				NotificationCenter.default.post(
					name: Notification.Name("AppBoxOpenDashboardNotification"),
					object: self?.ipaUploadInfo?.appShortShareableURL?.absoluteString)
				self?.dismiss(nil)
			},
			onClose: { [weak self] in
				self?.dismiss(nil)
			})
	}

    public override func viewDidLoad() {
        super.viewDidLoad()
        if let info = ipaUploadInfo {
            _ = ABProject.addProject(withIPAUploadInfo: info)
        }
    }

    private func presentQRCodeSheet() {
        let qr = QRCodeViewController()
        qr.ipaUploadInfo = ipaUploadInfo
        presentAsSheet(qr)
    }
}
