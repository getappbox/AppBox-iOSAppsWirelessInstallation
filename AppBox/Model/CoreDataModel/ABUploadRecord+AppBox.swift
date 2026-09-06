//
//  ABUploadRecord+AppBox.swift
//  AppBox

import Foundation
import AppBoxCore

extension ABUploadRecord {

    /// Reconstruct an `IPAUploadInfo` from this record (used to re-open a build from the dashboard).
    public var ipaUploadInfo: IPAUploadInfo {
        let info = IPAUploadInfo()

        info.name = project?.name
        info.identifer = project?.bundleIdentifier
        info.version = version
        info.build = build
        info.buildType = buildType

        info.dbIPAFullPath = dbIPAFullPath.flatMap { URL(string: $0) }
        info.dbManifestFullPath = dbManifestFullPath.flatMap { URL(string: $0) }
        info.dbAppInfoJSONFullPath = dbAppInfoFullPath.flatMap { URL(string: $0) }
        info.dbDirectory = dbDirectroy.flatMap { URL(string: $0) }
        info.ipaFileDBShareableURL = dbSharedIPAURL.flatMap { URL(string: $0) }
        info.manifestFileSharableURL = dbSharedManifestURL.flatMap { URL(string: $0) }
        info.uniquelinkShareableURL = dbSharedAppInfoURL.flatMap { URL(string: $0) }
        info.appShortShareableURL = shortURL.flatMap { URL(string: $0) }

        info.isKeepSameLinkEnabled = keepSameLink?.boolValue ?? false

        if let localBuildPath { info.ipaFullPath = URL(fileURLWithPath: localBuildPath) }

        return info
    }
}
