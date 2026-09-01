//
//  ABProject+AppBox.swift
//  AppBox

import Foundation
import CoreData
import AppBoxCore

extension ABProject {

    /// Find-or-create the project for this IPA, append a new UploadRecord (with its provisioning profile + devices), and save.
    public static func addProject(withIPAUploadInfo info: IPAUploadInfo) -> ABProject? {
        do {
            let context = try CoreDataStack.shared.loadViewContext()
            return try BuildRecordStore.save(info.buildRecordInput, in: context) {
                try CoreDataStack.shared.saveChanges()
            }
        } catch {
            _ = Common.showAlert(withTitle: "Error", andMessage: error.localizedDescription)
            return nil
        }
    }
}

private extension IPAUploadInfo {

    /// The bundle-level folder, matching the old `pathComponents[0] + pathComponents[1]` derivation.
    var dbFolderName: String {
        let components = dbDirectory?.pathComponents ?? []
        return components.count > 1 ? components[0] + components[1] : ""
    }

    var buildRecordInput: BuildRecordInput {
        BuildRecordInput(
            identifier: identifer ?? "",
            name: name ?? "",
            version: version ?? "",
            build: build ?? "",
            buildType: buildType,
            localIPAPath: (ipaFullPath as NSURL?)?.resourceSpecifier?.removingPercentEncoding,
            keepSameLink: isKeepSameLinkEnabled,
            bundleDirectory: dbFolderName,
            buildDirectory: dbDirectory?.absoluteString ?? "",
            ipaRemotePath: dbIPAFullPath?.absoluteString ?? "",
            manifestRemotePath: dbManifestFullPath?.absoluteString ?? "",
            appInfoRemotePath: dbAppInfoJSONFullPath?.absoluteString ?? "",
            sharedIPAURL: ipaFileDBShareableURL?.absoluteString,
            sharedManifestURL: manifestFileSharableURL?.absoluteString,
            shortURL: appShortShareableURL?.absoluteString,
            provisioning: mobileProvision.map {
                MobileProvisionInfo(isValid: $0.isValid, uuid: $0.uuid, teamId: $0.teamId,
                                    teamName: $0.teamName, buildType: $0.buildType,
                                    createDate: $0.createDate, expirationDate: $0.expirationDate,
                                    provisionedDevices: $0.provisionedDevices)
            })
    }
}
