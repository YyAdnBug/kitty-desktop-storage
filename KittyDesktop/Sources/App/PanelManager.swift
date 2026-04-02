import AppKit

final class PanelManager: FencePanelDelegate {

    static let shared = PanelManager()

    private(set) var panels: [FencePanel] = []
    private var configs: [PanelConfig] = []
    private let settingsController = PanelSettingsHostingController()
    private var panelCounter: Int = 0

    private init() {}

    // MARK: - Lifecycle

    func loadPanels() {
        configs = PanelStore.shared.loadAll()
        panelCounter = configs.count

        for config in configs {
            let panel = createPanelWindow(config: config)
            panels.append(panel)
            panel.orderFront(nil)
        }
    }

    func savePanels() {
        configs = panels.map { $0.panelConfig }
        PanelStore.shared.saveImmediately(configs)
    }

    // MARK: - Panel Creation

    func createNewPanel(at point: NSPoint? = nil) {
        panelCounter += 1
        let origin: NSPoint
        if let point = point {
            origin = NSPoint(
                x: point.x - PanelConfig.defaultWidth / 2,
                y: point.y - PanelConfig.defaultHeight / 2
            )
        } else {
            let screen = NSScreen.main ?? NSScreen.screens.first!
            let center = NSPoint(
                x: screen.visibleFrame.midX - PanelConfig.defaultWidth / 2,
                y: screen.visibleFrame.midY - PanelConfig.defaultHeight / 2
            )
            let offset = CGFloat(panels.count) * 30
            origin = NSPoint(x: center.x + offset, y: center.y - offset)
        }

        let frame = NSRect(
            x: origin.x,
            y: origin.y,
            width: PanelConfig.defaultWidth,
            height: PanelConfig.defaultHeight
        )
        let config = PanelConfig(title: "收纳区 \(panelCounter)", frame: frame)
        configs.append(config)

        let panel = createPanelWindow(config: config)
        panels.append(panel)
        panel.orderFront(nil)
        PanelStore.shared.saveAll(configs)
    }

    private func createPanelWindow(config: PanelConfig) -> FencePanel {
        let panel = FencePanel(config: config)
        panel.panelDelegate = self

        panel.fencePanelView.titleBar.onTitleChanged = { [weak self, weak panel] newTitle in
            guard let panel else { return }
            panel.panelConfig.title = newTitle
            self?.syncConfig(for: panel)
        }

        panel.fencePanelView.fileGrid.onItemRemoved = { [weak self, weak panel] item in
            guard let panel else { return }
            panel.panelConfig.items.removeAll { $0.id == item.id }
            panel.fencePanelView.fileGrid.reloadData(with: panel.panelConfig)
            self?.syncConfig(for: panel)
        }

        panel.fencePanelView.fileGrid.onItemTrashed = { [weak self, weak panel] item in
            guard let panel else { return }
            TrashHandler.confirmAndTrash(item: item, relativeTo: panel) { success in
                if success {
                    panel.panelConfig.items.removeAll { $0.id == item.id }
                    panel.fencePanelView.fileGrid.reloadData(with: panel.panelConfig)
                    self?.syncConfig(for: panel)
                }
            }
        }

        return panel
    }

    // MARK: - Panel Deletion

    func deletePanel(_ panel: FencePanel) {
        let alert = NSAlert()
        alert.messageText = "确定要删除面板「\(panel.panelConfig.title)」？"
        alert.informativeText = "面板中的文件引用将被清除，但原始文件不受影响。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "删除面板")
        alert.addButton(withTitle: "取消")

        alert.beginSheetModal(for: panel) { [weak self] response in
            guard response == .alertFirstButtonReturn else { return }
            self?.performDeletePanel(panel)
        }
    }

    private func performDeletePanel(_ panel: FencePanel) {
        panel.orderOut(nil)
        panels.removeAll { $0 === panel }
        configs.removeAll { $0.id == panel.panelConfig.id }
        PanelStore.shared.saveAll(configs)
    }

    // MARK: - FencePanelDelegate

    func panelDidUpdateConfig(_ panel: FencePanel) {
        syncConfig(for: panel)
    }

    func panelDidRequestDelete(_ panel: FencePanel) {
        deletePanel(panel)
    }

    func panelDidRequestSettings(_ panel: FencePanel) {
        settingsController.show(for: panel, relativeTo: panel.fencePanelView.titleBar)
    }

    // MARK: - Config Sync

    private func syncConfig(for panel: FencePanel) {
        if let index = configs.firstIndex(where: { $0.id == panel.panelConfig.id }) {
            configs[index] = panel.panelConfig
        }
        PanelStore.shared.saveAll(configs)
    }

    // MARK: - Screen Change

    func handleScreenChange() {
        for panel in panels {
            guard let screen = panel.screen ?? NSScreen.main else { continue }
            let sf = screen.visibleFrame
            var f = panel.frame

            // Ensure panel stays within visible area
            if f.maxX > sf.maxX { f.origin.x = sf.maxX - f.width }
            if f.minX < sf.minX { f.origin.x = sf.minX }
            if f.maxY > sf.maxY { f.origin.y = sf.maxY - f.height }
            if f.minY < sf.minY { f.origin.y = sf.minY }

            if f != panel.frame {
                panel.setFrame(f, display: true)
                panel.syncFrameToConfig()
                syncConfig(for: panel)
            }

            // Re-apply edge snapping if needed
            if let side = panel.panelConfig.snapSide, panel.panelConfig.isCollapsed {
                EdgeSnapper.applyCollapsedFrame(to: panel, side: side, animated: false)
            }
        }
    }
}
