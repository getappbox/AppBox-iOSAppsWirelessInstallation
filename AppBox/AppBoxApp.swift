//
//  AppBoxApp.swift
//  AppBox

import SwiftUI
import AppKit

@main
struct AppBoxApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        Window("AppBox - iOS App Wireless Installation", id: "home") {
            HomeRootView()
                .frame(minWidth: 780, minHeight: 400)
        }
        .defaultSize(width: 780, height: 400)
        .commands { appCommands }

        Window("AppBox Dashboard", id: "dashboard") {
            DashboardControllerView()
                .frame(minWidth: 940, minHeight: 600)
        }
        .defaultSize(width: 940, height: 600)
        .defaultLaunchBehavior(.suppressed)
    }

    @CommandsBuilder private var appCommands: some Commands {
        CommandGroup(after: .appInfo) {
            Button("Check for Update") { NSApp.checkForUpdateTapped(nil) }
        }
        CommandGroup(replacing: .appSettings) {
            Button("Preferences…") { PreferencesTabViewController.presentPreferences() }
                .keyboardShortcut(",", modifiers: .command)
        }

        CommandGroup(replacing: .newItem) {
            Button("Home") { openWindow(id: "home") }
                .keyboardShortcut("o", modifiers: .command)
            Button("Dashboard") { openWindow(id: "dashboard") }
                .keyboardShortcut("d", modifiers: .command)
        }

        CommandGroup(replacing: .help) {
			Button("Help") {
				NSApp.helpButtonTapped(nil)
			}
			.keyboardShortcut("?", modifiers: .command)
            Divider()
			Button("License") {
				NSApp.licenseTapped(nil)
			}
			Button("Release Notes") {
				NSApp.releaseNotesTapped(nil)
			}
        }
    }
}

// MARK: - AppKit hosting

/// Wraps the Home content so AppKit code (the ShowLink sheet's "Show in Dashboard") can open the SwiftUI dashboard window: `openWindow` only exists in the SwiftUI environment, so a notification bridges the two worlds.
private struct HomeRootView: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        HomeControllerView()
            .onReceive(NotificationCenter.default.publisher(
                for: Notification.Name("AppBoxOpenDashboardNotification"))) { notification in
                openWindow(id: "dashboard")
                DashboardControllerView.reveal(notification.object as? String)
            }
    }
}

private struct HomeControllerView: NSViewControllerRepresentable {
    @MainActor private static let shared = HomeViewController()
    func makeNSViewController(context: Context) -> HomeViewController { Self.shared }
    func updateNSViewController(_ nsViewController: HomeViewController, context: Context) {}
}

private struct DashboardControllerView: NSViewControllerRepresentable {
    @MainActor private static let shared = DashboardViewController()

    @MainActor static func reveal(_ shortURL: String?) {
        guard let shortURL, !shortURL.isEmpty else { return }
        shared.revealBuild(shortURL: shortURL)
    }

    func makeNSViewController(context: Context) -> DashboardViewController { Self.shared }
    func updateNSViewController(_ nsViewController: DashboardViewController, context: Context) {}
}
