//
//  DropBoxUploadManager.swift
//
//
//  Created by Vineet Choudhary on 16/09/23.
//

import Foundation
import SwiftyDropbox

final class DropBoxUploadManager: UploadManager {
	let dropBoxClient: DropboxClient

	init(settings: UploadManagerSettings) throws {
		guard let dropboxSettings = settings as? DropBoxUploadManagerSettings else {
			throw AppBoxError.uploadError(.sdk(.initializationFailed))
		}

		DropboxClientsManager.setupWithAppKeyDesktop(dropboxSettings.appKey)
		dropBoxClient = DropboxClient(accessToken: dropboxSettings.accessToken)
		Log.debug("Dropbox setup successfully.")
	}

	func uploadIPA(url: URL) -> URL {
		url
//		dropBoxClient.files.upload(
//			path: <#T##String#>,
//			mode: .add,
//			autorename: false,
//			input: Data(contentsOf: url))
	}
}
