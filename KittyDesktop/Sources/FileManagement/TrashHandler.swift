import AppKit

enum TrashHandler {

    static func moveToTrash(item: PanelItem, completion: @escaping (Bool) -> Void) {
        guard let url = BookmarkManager.shared.resolveBookmark(item.bookmarkData) else {
            completion(false)
            return
        }
        _ = BookmarkManager.shared.startAccessing(url)
        defer { BookmarkManager.shared.stopAccessing(url) }

        NSWorkspace.shared.recycle([url]) { _, error in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
    }

    static func confirmAndTrash(
        item: PanelItem,
        relativeTo window: NSWindow?,
        completion: @escaping (Bool) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = "确定要将「\(item.displayName)」移到废纸篓？"
        alert.informativeText = "此操作会删除原始文件，可从废纸篓恢复。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "移到废纸篓")
        alert.addButton(withTitle: "取消")

        let handler: (NSApplication.ModalResponse) -> Void = { response in
            guard response == .alertFirstButtonReturn else {
                completion(false)
                return
            }
            moveToTrash(item: item, completion: completion)
        }

        if let window = window {
            alert.beginSheetModal(for: window, completionHandler: handler)
        } else {
            let response = alert.runModal()
            handler(response)
        }
    }

    static func revealInFinder(item: PanelItem) {
        guard let url = BookmarkManager.shared.resolveBookmark(item.bookmarkData) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    static func openFile(item: PanelItem) {
        guard let url = BookmarkManager.shared.resolveBookmark(item.bookmarkData) else { return }
        _ = BookmarkManager.shared.startAccessing(url)
        NSWorkspace.shared.open(url)
        BookmarkManager.shared.stopAccessing(url)
    }
}
