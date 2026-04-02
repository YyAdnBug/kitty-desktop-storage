import AppKit

protocol FencePanelDelegate: AnyObject {
    func panelDidUpdateConfig(_ panel: FencePanel)
    func panelDidRequestDelete(_ panel: FencePanel)
    func panelDidRequestSettings(_ panel: FencePanel)
}

final class FencePanel: NSPanel {

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
    }

    private func setupWindow() {
        level = .floating

        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary,
        ]

        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        alphaValue = CGFloat(panelConfig.opacity)
        minSize = NSSize(width: PanelConfig.minWidth, height: PanelConfig.minHeight)

        if panelConfig.isCollapsed, let snap = panelConfig.snapSide {
            expandedFrame = panelConfig.expandedFrame?.nsRect ?? frame
            EdgeSnapper.applyCollapsedFrame(to: self, side: snap, animated: false)
        }
    }

    private func setupContentView() {
        fencePanelView = FencePanelView(panel: self)
        contentView = fencePanelView
    }

    // MARK: - Config Updates

    func applyConfigChanges() {
        alphaValue = CGFloat(panelConfig.opacity)
        fencePanelView.needsDisplay = true
        fencePanelView.titleBar.updateTitle(panelConfig.title)
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

    override func cancelOperation(_ sender: Any?) {
        fencePanelView.titleBar.cancelEditing()
    }
}
