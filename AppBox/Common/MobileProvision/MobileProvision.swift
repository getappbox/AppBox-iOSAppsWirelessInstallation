//
//  MobileProvision.swift
//  AppBox

import Foundation
import AppBoxCore

public final class MobileProvision: NSObject {

    public var isValid: Bool = false
    public var uuid: String?
    public var teamId: String?
    public var teamName: String?
    public var buildType: String?
    public var createDate: Date?
    public var expirationDate: Date?
    public var provisionedDevices: [String]?

    public init(path: String) {
        super.init()
        let info = ABMobileProvisionParser.parseFile(atPath: path)
        isValid = info.isValid
        uuid = info.uuid
        teamId = info.teamId
        teamName = info.teamName
        buildType = info.buildType
        createDate = info.createDate
        expirationDate = info.expirationDate
        provisionedDevices = info.provisionedDevices
    }

    public init(_ info: MobileProvisionInfo) {
        super.init()
        isValid = info.isValid
        uuid = info.uuid
        teamId = info.teamId
        teamName = info.teamName
        buildType = info.buildType
        createDate = info.createDate
        expirationDate = info.expirationDate
        provisionedDevices = info.provisionedDevices
    }
}
