import AppKit

final class FencePanelView: NSView {

    unowned let panel: FencePanel
    let titleBar: PanelTitleBar
    let fileGrid: FileGridView

    private let resizeMargin: CGFloat = 6.0
    private var dragType: DragType = .none
    private var dragOrigin: NSPoint = .zero
    private var originalFrame: NSRect = .zero
    private var showDropHighlight = false
    var isHighlighted = false { didSet { needsDisplay = true } }

    enum DragType {
        case none, move
        case resizeLeft, resizeRight, resizeTop, resizeBottom
        case resizeTopLeft, resizeTopRight, resizeBottomLeft, resizeBottomRight
    }

    init(panel: FencePanel) {
        self.panel = panel
        self.titleBar = PanelTitleBar(config: panel.panelConfig)
        self.fileGrid = FileGridView(config: panel.panelConfig)
        super.init(frame: panel.panelConfig.frame.nsRect)
        wantsLayer = true
        setupSubviews()
        setupTrackingArea()
        registerForDraggedTypes([.fileURL])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    private func setupSubviews() {
        addSubview(titleBar)
        addSubview(fileGrid)

        titleBar.translatesAutoresizingMaskIntoConstraints = false
        fileGrid.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleBar.topAnchor.constraint(equalTo: topAnchor),
            titleBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleBar.heightAnchor.constraint(equalToConstant: PanelConfig.titleBarHeight),

            fileGrid.topAnchor.constraint(equalTo: titleBar.bottomAnchor),
            fileGrid.leadingAnchor.constraint(equalTo: leadingAnchor),
            fileGrid.trailingAnchor.constraint(equalTo: trailingAnchor),
            fileGrid.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        titleBar.onSettingsClicked = { [weak self] in
            guard let self else { return }
            self.panel.panelDelegate?.panelDidRequestSettings(self.panel)
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds, xRadius: 10, yRadius: 10)
        panel.panelConfig.backgroundColor.nsColor.setFill()
        path.fill()

        if showDropHighlight {
            NSColor.controlAccentColor.withAlphaComponent(0.4).setStroke()
            let inset = bounds.insetBy(dx: 2, dy: 2)
            let strokePath = NSBezierPath(roundedRect: inset, xRadius: 9, yRadius: 9)
            strokePath.lineWidth = 3
            strokePath.stroke()
        } else if isHighlighted {
            NSColor.controlAccentColor.withAlphaComponent(0.6).setStroke()
            let inset = bounds.insetBy(dx: 1, dy: 1)
            let strokePath = NSBezierPath(roundedRect: inset, xRadius: 9, yRadius: 9)
            strokePath.lineWidth = 2
            strokePath.stroke()
        }
    }

    override var isFlipped: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // MARK: - Tracking Area

    private func setupTrackingArea() {
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .mouseMoved, .cursorUpdate,
                      .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    // MARK: - Hit Test for Drag/Resize

    private func detectDragType(at point: NSPoint) -> DragType {
        let b = bounds
        let m = resizeMargin
        let inLeft   = point.x < m
        let inRight  = point.x > b.width - m
        let inBottom = point.y < m
        let inTop    = point.y > b.height - m

        if inLeft && inTop { return .resizeTopLeft }
        if inRight && inTop { return .resizeTopRight }
        if inLeft && inBottom { return .resizeBottomLeft }
        if inRight && inBottom { return .resizeBottomRight }
        if inLeft { return .resizeLeft }
        if inRight { return .resizeRight }
        if inTop { return .resizeTop }
        if inBottom { return .resizeBottom }

        if point.y > b.height - PanelConfig.titleBarHeight {
            return .move
        }
        return .none
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        let local = convert(event.locationInWindow, from: nil)
        dragType = detectDragType(at: local)
        if dragType != .none {
            dragOrigin = NSEvent.mouseLocation
            originalFrame = panel.frame
        } else {
            super.mouseDown(with: event)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard dragType != .none else {
            super.mouseDragged(with: event)
            return
        }

        let current = NSEvent.mouseLocation
        let dx = current.x - dragOrigin.x
        let dy = current.y - dragOrigin.y
        let minW = PanelConfig.minWidth
        let minH = PanelConfig.minHeight

        var f = originalFrame

        switch dragType {
        case .move:
            f.origin.x += dx
            f.origin.y += dy

        case .resizeRight:
            f.size.width = max(minW, originalFrame.width + dx)
        case .resizeLeft:
            let newW = max(minW, originalFrame.width - dx)
            f.origin.x = originalFrame.maxX - newW
            f.size.width = newW
        case .resizeTop:
            f.size.height = max(minH, originalFrame.height + dy)
        case .resizeBottom:
            let newH = max(minH, originalFrame.height - dy)
            f.origin.y = originalFrame.maxY - newH
            f.size.height = newH

        case .resizeTopRight:
            f.size.width = max(minW, originalFrame.width + dx)
            f.size.height = max(minH, originalFrame.height + dy)
        case .resizeTopLeft:
            let newW = max(minW, originalFrame.width - dx)
            f.origin.x = originalFrame.maxX - newW
            f.size.width = newW
            f.size.height = max(minH, originalFrame.height + dy)
        case .resizeBottomRight:
            f.size.width = max(minW, originalFrame.width + dx)
            let newH = max(minH, originalFrame.height - dy)
            f.origin.y = originalFrame.maxY - newH
            f.size.height = newH
        case .resizeBottomLeft:
            let newW = max(minW, originalFrame.width - dx)
            f.origin.x = originalFrame.maxX - newW
            f.size.width = newW
            let newH = max(minH, originalFrame.height - dy)
            f.origin.y = originalFrame.maxY - newH
            f.size.height = newH

        case .none:
            break
        }

        panel.setFrame(f, display: true, animate: false)
    }

    override func mouseUp(with event: NSEvent) {
        if dragType != .none {
            panel.syncFrameToConfig()
            if dragType == .move {
                EdgeSnapper.snapIfNeeded(panel: panel)
            }
            panel.panelDelegate?.panelDidUpdateConfig(panel)
            dragType = .none
        } else {
            super.mouseUp(with: event)
        }
    }

    override func cursorUpdate(with event: NSEvent) {
        let local = convert(event.locationInWindow, from: nil)
        switch detectDragType(at: local) {
        case .resizeLeft, .resizeRight:
            NSCursor.resizeLeftRight.set()
        case .resizeTop, .resizeBottom:
            NSCursor.resizeUpDown.set()
        case .resizeTopLeft, .resizeBottomRight:
            NSCursor.crosshair.set()
        case .resizeTopRight, .resizeBottomLeft:
            NSCursor.crosshair.set()
        case .move:
            NSCursor.openHand.set()
        case .none:
            NSCursor.arrow.set()
        }
    }

    // MARK: - Drag & Drop (File Receiving)

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) else {
            return []
        }
        showDropHighlight = true
        needsDisplay = true
        return .link
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return sender.draggingPasteboard.canReadObject(
            forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]
        ) ? .link : []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        showDropHighlight = false
        needsDisplay = true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        showDropHighlight = false
        needsDisplay = true

        guard let urls = sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] else { return false }

        var added = false
        var skippedDuplicate = 0
        var failedCount = 0

        for url in urls {
            if panel.panelConfig.items.contains(where: {
                $0.resolveURL()?.standardizedFileURL == url.standardizedFileURL
            }) {
                skippedDuplicate += 1
                continue
            }
            if let item = try? PanelItem(url: url) {
                panel.panelConfig.items.append(item)
                if GlobalPreferences.shared.hideOriginalAfterAdd {
                    FileHideManager.shared.hideFile(for: item)
                }
                added = true
            } else {
                failedCount += 1
            }
        }

        if added {
            fileGrid.reloadData(with: panel.panelConfig)
            panel.panelDelegate?.panelDidUpdateConfig(panel)
        }

        if failedCount > 0 {
            let alert = NSAlert()
            alert.messageText = "部分文件添加失败"
            alert.informativeText = "有 \(failedCount) 个文件无法添加到面板（可能没有读取权限）。"
            alert.alertStyle = .warning
            alert.runModal()
        }

        return added || skippedDuplicate > 0
    }

    // MARK: - Right-Click Menu on Background

    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu()

        let newItem = NSMenuItem(title: "新建面板", action: #selector(createNewPanel), keyEquivalent: "")
        newItem.target = self
        menu.addItem(newItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "面板设置…", action: #selector(requestSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let deleteItem = NSMenuItem(title: "删除此面板", action: #selector(requestDelete), keyEquivalent: "")
        deleteItem.target = self
        deleteItem.attributedTitle = NSAttributedString(
            string: "删除此面板",
            attributes: [.foregroundColor: NSColor.systemRed]
        )
        menu.addItem(deleteItem)
        return menu
    }

    @objc private func createNewPanel() {
        PanelManager.shared.createNewPanel()
    }

    @objc private func requestSettings() {
        panel.panelDelegate?.panelDidRequestSettings(panel)
    }

    @objc private func requestDelete() {
        panel.panelDelegate?.panelDidRequestDelete(panel)
    }
}
