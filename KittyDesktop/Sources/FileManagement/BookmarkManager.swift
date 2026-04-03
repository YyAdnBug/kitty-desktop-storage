import AppKit
import QuickLookThumbnailing

final class BookmarkManager {
    static let shared = BookmarkManager()
    private var accessedURLs: Set<URL> = []
    private var thumbnailCache = NSCache<NSString, NSImage>()

    private init() {
        thumbnailCache.countLimit = 200
    }

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

    private static let thumbnailExtensions: Set<String> = [
        "png", "jpg", "jpeg", "gif", "webp", "tiff", "tif", "bmp", "heic", "heif",
        "pdf", "psd", "ai", "eps", "svg",
        "mp4", "mov", "avi", "mkv", "webm",
        "pages", "numbers", "keynote", "doc", "docx", "xls", "xlsx", "pptx",
    ]

    func icon(for item: PanelItem, size: NSSize = NSSize(width: 48, height: 48)) -> NSImage {
        guard let url = resolveBookmark(item.bookmarkData) else {
            let fallback = NSWorkspace.shared.icon(for: item.isDirectory ? .folder : .data)
            fallback.size = size
            return fallback
        }

        let cacheKey = "\(url.path)_\(Int(size.width))" as NSString
        if let cached = thumbnailCache.object(forKey: cacheKey) {
            return cached
        }

        if item.isDirectory {
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = size
            thumbnailCache.setObject(icon, forKey: cacheKey)
            return icon
        }

        let ext = url.pathExtension.lowercased()
        if Self.thumbnailExtensions.contains(ext) {
            requestThumbnail(url: url, size: size, cacheKey: cacheKey)
        }

        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = size
        return icon
    }

    private func requestThumbnail(url: URL, size: NSSize, cacheKey: NSString) {
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: size.width * scale, height: size.height * scale),
            scale: scale,
            representationTypes: .thumbnail
        )
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { [weak self] rep, _ in
            guard let rep else { return }
            let image = NSImage(cgImage: rep.cgImage, size: size)
            DispatchQueue.main.async {
                self?.thumbnailCache.setObject(image, forKey: cacheKey)
                NotificationCenter.default.post(name: .thumbnailDidLoad, object: nil,
                                                userInfo: ["path": url.path])
            }
        }
    }
}

extension Notification.Name {
    static let thumbnailDidLoad = Notification.Name("thumbnailDidLoad")
}
