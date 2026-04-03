import AppKit
import UniformTypeIdentifiers

final class PanelStore {
    static let shared = PanelStore()

    private let storageURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var saveDebounceWorkItem: DispatchWorkItem?

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let appDir = appSupport.appendingPathComponent("KittyDesktop", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.storageURL = appDir.appendingPathComponent("panels.json")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func loadAll() -> [PanelConfig] {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: storageURL)
            return try decoder.decode([PanelConfig].self, from: data)
        } catch {
            NSLog("[PanelStore] Failed to load: \(error)")
            return []
        }
    }

    func saveAll(_ configs: [PanelConfig]) {
        saveDebounceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.performSave(configs)
        }
        saveDebounceWorkItem = workItem
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    func saveImmediately(_ configs: [PanelConfig]) {
        performSave(configs)
    }

    private func performSave(_ configs: [PanelConfig]) {
        do {
            let data = try encoder.encode(configs)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            NSLog("[PanelStore] Failed to save: \(error)")
        }
    }

    func save(panel: PanelConfig, in configs: inout [PanelConfig]) {
        if let index = configs.firstIndex(where: { $0.id == panel.id }) {
            configs[index] = panel
        } else {
            configs.append(panel)
        }
        saveAll(configs)
    }

    func remove(panelID: UUID, from configs: inout [PanelConfig]) {
        configs.removeAll { $0.id == panelID }
        saveAll(configs)
    }

    // MARK: - Import / Export

    func exportConfigs(_ configs: [PanelConfig]) {
        let savePanel = NSSavePanel()
        savePanel.title = "导出面板布局"
        savePanel.nameFieldStringValue = "KittyDesktop_Layout.json"
        savePanel.allowedContentTypes = [.json]
        savePanel.canCreateDirectories = true

        guard savePanel.runModal() == .OK, let url = savePanel.url else { return }

        do {
            let data = try encoder.encode(configs)
            try data.write(to: url, options: .atomic)
            let alert = NSAlert()
            alert.messageText = "导出成功"
            alert.informativeText = "已导出 \(configs.count) 个面板配置。"
            alert.alertStyle = .informational
            alert.runModal()
        } catch {
            let alert = NSAlert()
            alert.messageText = "导出失败"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.runModal()
        }
    }

    func importConfigs() -> [PanelConfig]? {
        let openPanel = NSOpenPanel()
        openPanel.title = "导入面板布局"
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false

        guard openPanel.runModal() == .OK, let url = openPanel.url else { return nil }

        do {
            let data = try Data(contentsOf: url)
            let configs = try decoder.decode([PanelConfig].self, from: data)
            return configs
        } catch {
            let alert = NSAlert()
            alert.messageText = "导入失败"
            alert.informativeText = "文件格式不正确：\(error.localizedDescription)"
            alert.alertStyle = .critical
            alert.runModal()
            return nil
        }
    }
}
