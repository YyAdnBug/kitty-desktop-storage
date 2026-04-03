import Foundation

final class FileHideManager {

    static let shared = FileHideManager()
    private init() {}

    /// Hide the original file in Finder (sets macOS `isHidden` flag).
    /// The file stays at its original path but becomes invisible.
    func hideFile(for item: PanelItem) {
        guard var url = item.resolveURL() else { return }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        var resourceValues = URLResourceValues()
        resourceValues.isHidden = true
        try? url.setResourceValues(resourceValues)
    }

    /// Reveal a previously hidden file (clears macOS `isHidden` flag).
    func unhideFile(for item: PanelItem) {
        guard var url = item.resolveURL() else { return }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        var resourceValues = URLResourceValues()
        resourceValues.isHidden = false
        try? url.setResourceValues(resourceValues)
    }

    /// Unhide all files referenced by a list of items.
    func unhideAll(items: [PanelItem]) {
        for item in items {
            unhideFile(for: item)
        }
    }

    /// Unhide every file across all panels (safety fallback).
    func unhideAllManagedFiles() {
        for panel in PanelManager.shared.panels {
            unhideAll(items: panel.panelConfig.items)
        }
    }
}
