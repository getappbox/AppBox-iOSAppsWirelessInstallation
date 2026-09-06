//
//  ABHudViewController.swift
//  AppBox

import AppKit
import SwiftUI

// MARK: - HUD state (drives the SwiftUI island)

private enum HudMode {
    case progress
    case status
    case result
}

private final class HudState: ObservableObject {
    @Published var status: String = ""
    @Published var mode: HudMode = .progress
    @Published var progress: Double? = nil
    @Published var success: Bool = true
}

// MARK: - SwiftUI HUD content (a centered, 70%-black rounded box)

private struct HudContentView: View {
    @ObservedObject var state: HudState

    var body: some View {
        VStack(spacing: 8) {
            switch state.mode {
            case .progress:
                Group {
                    if let fraction = state.progress {
                        ProgressView(value: fraction, total: 1)
                    } else {
                        ProgressView()
                    }
                }
                .progressViewStyle(.linear)
                .frame(width: 110)
                .tint(.white)
                .animation(.easeInOut(duration: 0.3), value: state.progress)
            case .result:
                Image(state.success ? "Check" : "Multiply")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            case .status:
                EmptyView()
            }

            if !state.status.isEmpty {
                Text(state.status)
					.font(IslandTypography.body.monospaced())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.25), value: state.status)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.75))
    }
}

// MARK: - Full-bleed click blocker

/// Swallows every mouse event in its bounds so the host view's content can't be interacted with while the HUD is up — the same role the nib's `DisabledView` root view played.
private final class HudContainerView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        return bounds.contains(local) ? self : nil
    }
    override func mouseDown(with event: NSEvent) { /* swallow */ }
    override func rightMouseDown(with event: NSEvent) { /* swallow */ }
    override func mouseDragged(with event: NSEvent) { /* swallow */ }
}

// MARK: - The HUD view controller

public final class ABHudViewController: NSViewController {

    private let hudState = HudState()
    private weak var hudSuperView: NSView?
    /// Bumped on every show so an earlier deferred `hideAllHud` can't dismiss a newer active HUD.
    private var hideGeneration = 0

    private static var huds: [ObjectIdentifier: ABHudViewController] = [:]

    /// Drop entries whose host view is gone (window closed mid-operation) — they'd otherwise leak for the app's lifetime, and a later view allocated at the recycled address would inherit them.
    private static func purgeStaleEntries() {
        huds = huds.filter { _, hud in hud.hudSuperView != nil }
    }

    public override func loadView() {
        let container = HudContainerView()
        let hosting = NSHostingView(rootView: HudContentView(state: hudState).islandTypography())
        hosting.sizingOptions = []
        hosting.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        view = container
    }

    // MARK: - Hud lifecycle

    /// Reuse-or-create the HUD overlaying `view`, or tear it down when `hide` is true.
    @discardableResult
    public static func hud(for view: NSView, hide: Bool) -> ABHudViewController? {
        purgeStaleEntries()
        let key = ObjectIdentifier(view)
        if hide {
            if let hud = huds[key] {
                hud.view.removeFromSuperview()
                huds.removeValue(forKey: key)
            }
            return nil
        }

        let hud: ABHudViewController
        if let existing = huds[key] {
            hud = existing
        } else {
            hud = ABHudViewController()
            hud.hudSuperView = view
            huds[key] = hud
        }
        hud.hideGeneration += 1
        hud.view.frame = view.bounds
        hud.view.autoresizingMask = [.width, .height]
        if !view.subviews.contains(hud.view) {
            view.addSubview(hud.view)
        }
        return hud
    }

    // MARK: - Convenience API (the former MBProgressHUD+ProgressHud category)

    public static func showStatus(_ status: String, onView view: NSView) {
        DispatchQueue.main.async {
            guard let hud = hud(for: view, hide: false) else { return }
            hud.hudState.status = status
            hud.hudState.mode = .progress
            hud.hudState.progress = nil
        }
    }

    public static func showStatus(_ status: String, witProgress progress: Double, onView view: NSView) {
        DispatchQueue.main.async {
            guard let hud = hud(for: view, hide: false) else { return }
            hud.hudState.progress = progress < 0 ? nil : progress
            hud.hudState.mode = .progress
            hud.hudState.status = status
        }
    }

    public static func showStatus(_ status: String, forSuccess success: Bool, onView view: NSView) {
        DispatchQueue.main.async {
            guard let hud = hud(for: view, hide: false) else { return }
            hud.hudState.status = status
            hud.hudState.success = success
            hud.hudState.mode = .result
            hideAllHud(fromView: view, after: 2)
        }
    }

    public static func showOnlyStatus(_ status: String, onView view: NSView) {
        DispatchQueue.main.async {
            guard let hud = hud(for: view, hide: false) else { return }
            hud.hudState.status = status
            hud.hudState.mode = .status
            hideAllHud(fromView: view, after: 3)
        }
    }

    public static func hideAllHud(fromView view: NSView, after sec: TimeInterval) {
        DispatchQueue.main.async {
            let key = ObjectIdentifier(view)
            let generation = huds[key]?.hideGeneration
            DispatchQueue.main.asyncAfter(deadline: .now() + sec) {
                guard huds[key]?.hideGeneration == generation else { return }
                _ = hud(for: view, hide: true)
            }
        }
    }
}
