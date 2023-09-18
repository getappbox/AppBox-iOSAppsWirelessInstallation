//
//  UploadError.swift
//
//
//  Created by Vineet Choudhary on 16/09/23.
//

import Foundation

enum UploadError: Error {
	case sdk(UploadSDKError)
}

enum UploadSDKError: Error {
	case initializationFailed
}
