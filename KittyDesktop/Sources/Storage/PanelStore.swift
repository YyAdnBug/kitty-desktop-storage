import Foundation

final class PanelStore {
    static let shared = PanelStore()

    private let storageURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var saveDebounceWorkItem: DispatchWorkItem?

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
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
}
