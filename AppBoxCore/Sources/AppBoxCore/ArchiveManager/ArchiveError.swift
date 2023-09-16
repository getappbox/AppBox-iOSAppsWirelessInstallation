//
//  ArchiveError.swift
//
//
//  Created by Vineet Choudhary on 16/09/23.
//

import Foundation

enum ArchiveError: Error {
	case unableToReadFile
	case unableToFindAppBundle
	case unableToFindInfoPlist
	case unableToFindMobileProvision
}
