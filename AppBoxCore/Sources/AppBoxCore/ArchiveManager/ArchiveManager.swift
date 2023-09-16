//
//  File.swift
//  
//
//  Created by Vineet Choudhary on 16/09/23.
//

import Foundation

protocol ArchiveManager {
	func unzip(file: URL) async throws -> ArchiveFiles
}
