//
//  AppBoxError.swift
//
//
//  Created by Vineet Choudhary on 16/09/23.
//

import Foundation

enum AppBoxError: Error {
	case archiveError(ArchiveError)
	case uploadError(UploadError)
}
