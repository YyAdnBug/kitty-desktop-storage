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

    @objc func unhideAllFiles() {
        FileHideManager.shared.unhideAllManagedFiles()
        let alert = NSAlert()
        alert.messageText = "已恢复所有文件"
        alert.informativeText = "所有被隐藏的原始文件已恢复显示。"
        alert.alertStyle = .informational
        alert.runModal()
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
