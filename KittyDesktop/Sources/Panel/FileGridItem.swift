import AppKit

final class FileGridItem: NSCollectionViewItem, NSDraggingSource {

    static let identifier = NSUserInterfaceItemIdentifier("FileGridItem")

    private let iconView = NSImageView()
    private let nameLabel = NSTextField()
    private var panelItem: PanelItem?

    var onRemoveFromPanel: ((PanelItem) -> Void)?
    var onMoveToTrash: ((PanelItem) -> Void)?
    var onRevealInFinder: ((PanelItem) -> Void)?

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 72, height: 80))
        container.wantsLayer = true
        self.view = container

        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconView)

        nameLabel.font = .systemFont(ofSize: 10)
        nameLabel.textColor = .white.withAlphaComponent(0.9)
        nameLabel.backgroundColor = .clear
        nameLabel.isBordered = false
        nameLabel.isEditable = false
        nameLabel.isSelectable = false
        nameLabel.alignment = .center
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.maximumNumberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),

            nameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 2),
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 2),
            nameLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -2),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -2),
        ])
    }

    func configure(with item: PanelItem) {
        self.panelItem = item
        nameLabel.stringValue = item.displayName
        iconView.image = BookmarkManager.shared.icon(for: item, size: NSSize(width: 40, height: 40))
    }

    // MARK: - Selection Highlight

    override var isSelected: Bool {
        didSet {
            view.layer?.backgroundColor = isSelected
                ? NSColor.controlAccentColor.withAlphaComponent(0.3).cgColor
                : nil
            view.layer?.cornerRadius = isSelected ? 6 : 0
        }
    }

    // MARK: - Double-Click → Open / Drag Source

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if event.clickCount == 2, let item = panelItem {
            TrashHandler.openFile(item: item)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let item = panelItem, let url = item.resolveURL() else {
            super.mouseDragged(with: event)
            return
        }
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(url.absoluteString, forType: .fileURL)

        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        let iconImage = BookmarkManager.shared.icon(for: item, size: NSSize(width: 40, height: 40))
        let iconRect = NSRect(origin: .zero, size: NSSize(width: 40, height: 40))
        draggingItem.setDraggingFrame(iconRect, contents: iconImage)

        view.beginDraggingSession(with: [draggingItem], event: event, source: self)
    }

    // MARK: - NSDraggingSource

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        context == .outsideApplication ? .copy : .move
    }

    // MARK: - Right-Click Menu

    override func rightMouseDown(with event: NSEvent) {
        guard let item = panelItem else { return }
        let menu = NSMenu()

        let openItem = NSMenuItem(title: "打开", action: #selector(openAction), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        let revealItem = NSMenuItem(title: "在 Finder 中显示", action: #selector(revealAction), keyEquivalent: "")
        revealItem.target = self
        menu.addItem(revealItem)

        menu.addItem(.separator())

        let removeItem = NSMenuItem(title: "从面板移除", action: #selector(removeAction), keyEquivalent: "")
        removeItem.target = self
        removeItem.representedObject = item
        menu.addItem(removeItem)

        menu.addItem(.separator())

        let trashItem = NSMenuItem(title: "移到废纸篓…", action: #selector(trashAction), keyEquivalent: "")
        trashItem.target = self
        trashItem.representedObject = item
        trashItem.attributedTitle = NSAttributedString(
            string: "移到废纸篓…",
            attributes: [.foregroundColor: NSColor.systemRed]
        )
        menu.addItem(trashItem)

        NSMenu.popUpContextMenu(menu, with: event, for: view)
    }

    @objc private func openAction() {
        guard let item = panelItem else { return }
        TrashHandler.openFile(item: item)
    }

    @objc private func revealAction() {
        guard let item = panelItem else { return }
        onRevealInFinder?(item)
    }

    @objc private func removeAction() {
        guard let item = panelItem else { return }
        onRemoveFromPanel?(item)
    }

    @objc private func trashAction() {
        guard let item = panelItem else { return }
        onMoveToTrash?(item)
    }
}
