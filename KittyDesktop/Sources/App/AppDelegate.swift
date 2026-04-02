import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController!
    private var preferencesController = PreferencesWindowController()
    private var panelManager: PanelManager { PanelManager.shared }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
        panelManager.loadPanels()

        if panelManager.panels.isEmpty {
            panelManager.createNewPanel()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
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

    @objc func showPreferences() {
        preferencesController.showWindow()
    }

    @objc private func screenParametersChanged() {
        panelManager.handleScreenChange()
    }
}
