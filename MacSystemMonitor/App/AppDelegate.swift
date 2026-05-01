import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let viewModel = SystemMonitorViewModel()
    private weak var window: NSWindow?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let win = NSApplication.shared.windows.first {
            window = win
            configureWindow(win)
        }
        setupStatusItem()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem?.button else { return }
        let icon = NSApp.applicationIconImage.copy() as! NSImage
        icon.size = NSSize(width: 18, height: 18)
        button.image = icon
        button.action = #selector(toggleWindow)
        button.target = self
    }

    @objc private func toggleWindow() {
        guard let win = window else { return }
        if win.isVisible {
            win.orderOut(nil)
        } else {
            win.orderFront(nil)
        }
    }

    private func configureWindow(_ win: NSWindow) {
        win.level = .floating
        win.isOpaque = false
        win.backgroundColor = .clear
        win.styleMask = [.resizable, .fullSizeContentView]
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.hidesOnDeactivate = false
        win.minSize = NSSize(width: 320, height: 400)
        win.standardWindowButton(.miniaturizeButton)?.isHidden = true
        win.standardWindowButton(.zoomButton)?.isHidden = true
        win.setContentSize(NSSize(width: 420, height: 700))
        win.center()
    }

    func setWindowOpacity(_ opacity: Double) {
        window?.alphaValue = opacity
    }
}
