import AppKit

protocol FencePanelDelegate: AnyObject {
    func panelDidUpdateConfig(_ panel: FencePanel)
    func panelDidRequestDelete(_ panel: FencePanel)
    func panelDidRequestSettings(_ panel: FencePanel)
}

final class FencePanel: NSPanel {

    static let desktopLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)

    var panelConfig: PanelConfig {
        didSet { panelDelegate?.panelDidUpdateConfig(self) }
    }

    weak var panelDelegate: FencePanelDelegate?

    var expandedFrame: NSRect?
    private(set) var fencePanelView: FencePanelView!

    init(config: PanelConfig) {
        self.panelConfig = config
        super.init(
            contentRect: config.frame.nsRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        setupWindow()
        setupContentView()
        observePreferences()
    }

    private func setupWindow() {
        applyWindowLevel()
        applyCollectionBehavior()

        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        alphaValue = CGFloat(panelConfig.opacity)
        minSize = NSSize(width: PanelConfig.minWidth, height: PanelConfig.minHeight)

        if panelConfig.isFolded, let ef = panelConfig.expandedFrame {
            foldedExpandedFrame = ef.nsRect
        }

        if panelConfig.isCollapsed, let snap = panelConfig.snapSide {
            expandedFrame = panelConfig.expandedFrame?.nsRect ?? frame
            EdgeSnapper.applyCollapsedFrame(to: self, side: snap, animated: false)
        }
    }

    private func setupContentView() {
        fencePanelView = FencePanelView(panel: self)
        contentView = fencePanelView
    }

    // MARK: - Window Level & Behavior

    func applyWindowLevel() {
        if panelConfig.alwaysOnTop || GlobalPreferences.shared.alwaysOnTop {
            level = .floating
        } else {
            level = FencePanel.desktopLevel
        }
    }

    func applyCollectionBehavior() {
        var behavior: NSWindow.CollectionBehavior = [
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary,
        ]
        if GlobalPreferences.shared.showInAllSpaces {
            behavior.insert(.canJoinAllSpaces)
        } else {
            behavior.insert(.moveToActiveSpace)
        }
        collectionBehavior = behavior
    }

    // MARK: - Preferences Observer

    private func observePreferences() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesChanged),
            name: .preferencesDidChange,
            object: nil
        )
    }

    @objc private func preferencesChanged() {
        applyWindowLevel()
        applyCollectionBehavior()
    }

    // MARK: - Config Updates

    func applyConfigChanges() {
        if panelConfig.isCollapsed {
            alphaValue = 0.5
        } else {
            alphaValue = CGFloat(panelConfig.opacity)
        }
        applyWindowLevel()
        fencePanelView.needsDisplay = true
        fencePanelView.titleBar.updateConfig(panelConfig)
    }

    private var foldedExpandedFrame: NSRect?

    func toggleFold() {
        panelConfig.isFolded.toggle()
        if panelConfig.isFolded {
            let fullFrame = frame
            foldedExpandedFrame = fullFrame
            let foldedRect = NSRect(x: fullFrame.origin.x,
                                    y: fullFrame.maxY - PanelConfig.titleBarHeight,
                                    width: fullFrame.width,
                                    height: PanelConfig.titleBarHeight)
            panelConfig.frame = CodableRect(foldedRect)
            panelConfig.expandedFrame = CodableRect(fullFrame)
            setFrame(foldedRect, display: true, animate: true)
        } else {
            let restored = foldedExpandedFrame ?? panelConfig.expandedFrame?.nsRect
                ?? NSRect(x: frame.origin.x,
                          y: frame.origin.y - PanelConfig.defaultHeight + PanelConfig.titleBarHeight,
                          width: frame.width,
                          height: PanelConfig.defaultHeight)
            panelConfig.frame = CodableRect(restored)
            panelConfig.expandedFrame = nil
            foldedExpandedFrame = nil
            setFrame(restored, display: true, animate: true)
        }
        panelDelegate?.panelDidUpdateConfig(self)
    }

    func updateFrame(to rect: NSRect) {
        panelConfig.frame = CodableRect(rect)
        setFrame(rect, display: true)
    }

    func syncFrameToConfig() {
        panelConfig.frame = CodableRect(frame)
    }

    // MARK: - Key Event

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown {
            PanelManager.shared.setActivePanel(self)
        }
        if event.type == .keyDown && event.keyCode == 49 && !isTextInputActive {
            fencePanelView.fileGrid.toggleQuickLook()
            return
        }
        super.sendEvent(event)
    }

    private var isTextInputActive: Bool {
        guard let responder = firstResponder else { return false }
        return responder is NSTextView || responder is NSTextField
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
