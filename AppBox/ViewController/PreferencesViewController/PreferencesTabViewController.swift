//
//  PreferencesTabViewController.swift
//  AppBox

import AppKit

public final class PreferencesTabViewController: NSViewController {

    private var panes: [NSViewController] = []

    public override func loadView() {
        var panes: [NSViewController] = []
        var tabs: [PreferencePane] = []

        let general = PreferencesViewController()
        panes.append(general)
        tabs.append(pane(for: general, title: "General", systemImage: "gearshape", tint: .systemGray))

        let account = AccountPreferencesViewController()
        panes.append(account)
        tabs.append(pane(for: account, title: "Accounts", systemImage: "person.crop.circle", tint: .systemTeal))

        let email = EmailPreferencesViewController()
        panes.append(email)
        tabs.append(pane(for: email, title: "Email", systemImage: "envelope", tint: .systemBlue))

        let thirdParty = ThirdPartyPreferencesViewController()
        panes.append(thirdParty)
        tabs.append(pane(for: thirdParty, title: "3rd Party", systemImage: "puzzlepiece.extension", tint: .systemPurple))

        let help = HelpPreferencesViewController()
        panes.append(help)
        tabs.append(pane(for: help, title: "Help", systemImage: "questionmark.circle", tint: .systemPink))

        self.panes = panes
        view = PreferencesContainerHost.makeView(panes: tabs)
    }

    private func pane(for controller: NSViewController, title: String, systemImage: String, tint: NSColor) -> PreferencePane {
        let view = controller.view
        view.layoutSubtreeIfNeeded()
        return PreferencePane(title: title, systemImage: systemImage, tint: tint, view: view, preferredSize: view.fittingSize)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "AppBox Preferences"
    }

    public override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.styleMask.remove(.resizable)
    }

    private static weak var current: PreferencesTabViewController?

    public class func presentPreferences() {
        if let existing = current, let window = existing.view.window {
            window.makeKeyAndOrderFront(nil)
            return
        }
        let host = (NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first { $0.isVisible })?.contentViewController
        guard let host else { return }
        let pref = PreferencesTabViewController()
        current = pref
        host.presentAsModalWindow(pref)
    }
}
