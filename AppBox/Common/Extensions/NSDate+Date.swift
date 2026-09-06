//
//  NSDate+Date.swift
//  AppBox

import Foundation

public extension NSDate {

    var string: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd, hh:mm a"
        return formatter.string(from: self as Date)
    }
}
