//
//  NSString+String.swift
//  AppBox

import Foundation

public extension NSString {

    func ipaURL() -> URL? {
        let url = URL(fileURLWithPath: self as String)
        return url.pathExtension.lowercased() == "ipa" ? url : nil
    }

    func isEmpty() -> Bool {
        return (self as String).trimmingCharacters(in: .whitespaces).isEmpty
    }
}
