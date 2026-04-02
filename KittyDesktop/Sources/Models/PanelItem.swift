import Foundation

struct PanelItem: Codable, Identifiable, Equatable {
    let id: UUID
    var bookmarkData: Data
    var displayName: String
    var addedDate: Date
    var isDirectory: Bool

    init(url: URL) throws {
        self.id = UUID()
        self.bookmarkData = try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: [.localizedNameKey, .isDirectoryKey],
            relativeTo: nil
        )
        let resourceValues = try url.resourceValues(forKeys: [.localizedNameKey, .isDirectoryKey])
        self.displayName = resourceValues.localizedName ?? url.lastPathComponent
        self.isDirectory = resourceValues.isDirectory ?? false
        self.addedDate = Date()
    }

    func resolveURL() -> URL? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return nil }

        if isStale {
            // Bookmark 已过期，需要刷新（调用方负责更新 bookmarkData）
            return url
        }
        return url
    }

    var isBookmarkStale: Bool {
        var isStale = false
        _ = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return isStale
    }
}
