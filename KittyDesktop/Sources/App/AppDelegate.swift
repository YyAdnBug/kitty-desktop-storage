import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController!
    private var panelManager: PanelManager { PanelManager.shared }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[KittyDesktop] applicationDidFinishLaunching START")

        statusBarController = StatusBarController()
        NSLog("[KittyDesktop] StatusBarController created")

        panelManager.loadPanels()
        NSLog("[KittyDesktop] Panels loaded: \(panelManager.panels.count)")

        if panelManager.panels.isEmpty {
            panelManager.createNewPanel()
            NSLog("[KittyDesktop] Created default panel")
        }

        for (i, panel) in panelManager.panels.enumerated() {
            NSLog("[KittyDesktop] Panel \(i): frame=\(panel.frame), isVisible=\(panel.isVisible), level=\(panel.level.rawValue)")
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NSLog("[KittyDesktop] applicationDidFinishLaunching DONE")
    }

    func applicationWillTerminate(_ notification: Notification) {
        panelManager.savePanels()
        BookmarkManager.shared.stopAccessingAll()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    // MARK: - Menu Actions

    @objc func createNewPanelFromMenu() {
        panelManager.createNewPanel()
    }

    @objc func showAllPanels() {
        for panel in panelManager.panels {
            panel.orderFront(nil)
            if panel.panelConfig.isCollapsed, let side = panel.panelConfig.snapSide {
                EdgeSnapper.applyCollapsedFrame(to: panel, side: side, animated: false)
            }
        }
    }

    @objc func hideAllPanels() {
        for panel in panelManager.panels {
            panel.orderOut(nil)
        }
    }

    @objc private func screenParametersChanged() {
        panelManager.handleScreenChange()
    }
}
