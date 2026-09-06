//
//  NSURL+URL.swift
//  AppBox

import Foundation

public extension NSURL {

    func isIPA() -> Bool {
        return pathExtension?.lowercased() == "ipa"
    }
}
