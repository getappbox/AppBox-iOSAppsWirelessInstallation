//
//  ProvisioningDetailsView.swift
//  AppBox

import SwiftUI
import AppKit
import AppBoxCore

struct ProvisioningDetailsInfo {
    let title: String
    let uuid: String
    let buildType: String
    let createDate: String
    let expirationDate: String
    let team: String
    let devices: String
    let deviceIds: [String]
    let mobileProvisionPath: String
}

struct ProvisioningDetailsView: View {
    let info: ProvisioningDetailsInfo
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: IslandMetrics.sectionSpacing) {
            Text(info.title).font(IslandTypography.headline)

            GroupBox {
                VStack(alignment: .leading, spacing: IslandMetrics.fieldSpacing) {
                    row("UUID", info.uuid)
                    row("Type", info.buildType)
                    row("Created", info.createDate)
                    row("Expires", info.expirationDate)
                    row("Team", info.team)
                    row("Devices", info.devices)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
            }

            HStack(spacing: 10) {
                Button("Copy Device UUIDs", action: copyDeviceUUIDs)
                Button("Show in Finder", action: showInFinder)
                Spacer()
                Button("Close", action: onClose).keyboardShortcut(.cancelAction)
            }
        }
        .padding(IslandMetrics.padding)
        .frame(width: IslandMetrics.sheetWidth)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label).font(IslandTypography.caption).foregroundColor(.secondary).frame(width: 90, alignment: .leading)
            Text(value.isEmpty ? "—" : value).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func copyDeviceUUIDs() {
        let joined = info.deviceIds.map { "\($0),\n" }.joined()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(joined, forType: .string)
    }

    private func showInFinder() {
        if FileManager.default.fileExists(atPath: info.mobileProvisionPath) {
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: info.mobileProvisionPath)])
        } else {
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = "File not found."
            alert.runModal()
        }
    }
}

public final class ProvisioningDetailsHost: NSObject {
    public static func makeView(record: ABUploadRecord, onClose: @escaping () -> Void) -> NSView {
        NSHostingView(rootView: ProvisioningDetailsView(info: info(from: record), onClose: onClose).islandTypography())
    }

    private static func info(from record: ABUploadRecord) -> ProvisioningDetailsInfo {
        let profile = record.provisioningProfile

        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd, hh:mm a"
        func dateString(_ date: Date?) -> String { date.map { formatter.string(from: $0) } ?? "" }

        let deviceIds = (profile?.provisionedDevices?.array as? [ABProvisionedDevice])?.compactMap { $0.deviceId } ?? []
        let buildType = profile?.buildType ?? ""
        let devices: String
        if buildType == "enterprise" {
            devices = "∞ Devices"
        } else {
            let count = profile?.provisionedDevices?.count ?? 0
            devices = "\(count) Device\(count > 1 ? "s" : "")"
        }

        let uuid = profile?.uuid ?? ""
        let path = ("~/Library/MobileDevice/Provisioning Profiles/\(uuid).mobileprovision" as NSString).expandingTildeInPath

        return ProvisioningDetailsInfo(
            title: "\(record.project?.name ?? "") - Provisioning Profile Details",
            uuid: uuid,
            buildType: buildType.capitalized,
            createDate: dateString(profile?.createDate),
            expirationDate: dateString(profile?.expirationDate),
            team: "\(profile?.teamId ?? "") - \(profile?.teamName ?? "")",
            devices: devices,
            deviceIds: deviceIds,
            mobileProvisionPath: path)
    }
}
