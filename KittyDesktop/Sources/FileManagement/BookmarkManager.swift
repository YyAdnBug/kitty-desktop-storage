import AppKit

final class BookmarkManager {
    static let shared = BookmarkManager()
    private var accessedURLs: Set<URL> = []

    private init() {}

    func resolveBookmark(_ data: Data) -> URL? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return nil }
        return url
    }

    func startAccessing(_ url: URL) -> Bool {
        guard url.startAccessingSecurityScopedResource() else { return false }
        accessedURLs.insert(url)
        return true
    }

    func stopAccessing(_ url: URL) {
        url.stopAccessingSecurityScopedResource()
        accessedURLs.remove(url)
    }

    func stopAccessingAll() {
        for url in accessedURLs {
            url.stopAccessingSecurityScopedResource()
        }
        accessedURLs.removeAll()
    }

    func refreshBookmark(for item: PanelItem) -> Data? {
        guard let url = resolveBookmark(item.bookmarkData) else { return nil }
        guard startAccessing(url) else { return nil }
        defer { stopAccessing(url) }
        return try? url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    func icon(for item: PanelItem, size: NSSize = NSSize(width: 48, height: 48)) -> NSImage {
        if let url = resolveBookmark(item.bookmarkData) {
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = size
            return icon
        }
        let icon = NSWorkspace.shared.icon(for: item.isDirectory ? .folder : .data)
        icon.size = size
        return icon
    }
}
