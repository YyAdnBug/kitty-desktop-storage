import AppKit
import Carbon.HIToolbox

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController!
    private var preferencesController = PreferencesWindowController()
    private var panelManager: PanelManager { PanelManager.shared }
    private var panelsVisible = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
        panelManager.loadPanels()

        if panelManager.panels.isEmpty {
            panelManager.createNewPanel()
        }

        if GlobalPreferences.shared.hideOriginalAfterAdd {
            FileHideManager.shared.hideAllManagedFiles()
        }

        registerGlobalHotkey()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    // MARK: - Global Hotkey (⌥⌘D)

    private func registerGlobalHotkey() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleHotkey(event)
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleHotkey(event)
            return event
        }
    }

    private func handleHotkey(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if event.keyCode == UInt16(kVK_ANSI_D) && flags == [.option, .command] {
            toggleAllPanels()
        }
    }

    @objc func toggleAllPanels() {
        if panelsVisible {
            hideAllPanels()
        } else {
            showAllPanels()
        }
        panelsVisible.toggle()
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

    @objc func exportLayout() {
        PanelStore.shared.exportConfigs(panelManager.panels.map { $0.panelConfig })
    }

    @objc func importLayout() {
        guard let configs = PanelStore.shared.importConfigs() else { return }

        let alert = NSAlert()
        alert.messageText = "导入 \(configs.count) 个面板"
        alert.informativeText = "是否替换当前所有面板？选择「合并」将追加到现有面板。"
        alert.addButton(withTitle: "替换")
        alert.addButton(withTitle: "合并")
        alert.addButton(withTitle: "取消")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            panelManager.replaceAllPanels(with: configs)
        } else if response == .alertSecondButtonReturn {
            panelManager.appendPanels(configs)
        }
    }

    @objc private func screenParametersChanged() {
        panelManager.handleScreenChange()
    }
}
