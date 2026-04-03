import AppKit

final class PanelTitleBar: NSView, NSTextFieldDelegate {

    private let titleLabel = NSTextField()
    private let lockIcon = NSImageView()
    private let settingsButton = NSButton()
    private var config: PanelConfig
    var onTitleChanged: ((String) -> Void)?
    var onSettingsClicked: (() -> Void)?
    var onDoubleClickBackground: (() -> Void)?

    init(config: PanelConfig) {
        self.config = config
        super.init(frame: .zero)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        wantsLayer = true

        // Lock icon
        lockIcon.image = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: "已锁定")
        lockIcon.contentTintColor = .white.withAlphaComponent(0.6)
        lockIcon.imageScaling = .scaleProportionallyDown
        lockIcon.isHidden = !config.isLocked
        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lockIcon)

        // Title label — editable on double-click
        titleLabel.stringValue = config.displayTitle
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .white.withAlphaComponent(0.9)
        titleLabel.backgroundColor = .clear
        titleLabel.isBordered = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.focusRingType = .none
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.cell?.truncatesLastVisibleLine = true
        titleLabel.delegate = self
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Settings (⋯) button
        settingsButton.bezelStyle = .inline
        settingsButton.isBordered = false
        settingsButton.title = ""
        settingsButton.image = NSImage(systemSymbolName: "ellipsis.circle", accessibilityDescription: "设置")
        settingsButton.contentTintColor = .white.withAlphaComponent(0.7)
        settingsButton.imageScaling = .scaleProportionallyDown
        settingsButton.target = self
        settingsButton.action = #selector(settingsClicked)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(settingsButton)

        NSLayoutConstraint.activate([
            lockIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            lockIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            lockIcon.widthAnchor.constraint(equalToConstant: 14),
            lockIcon.heightAnchor.constraint(equalToConstant: 14),

            titleLabel.leadingAnchor.constraint(equalTo: lockIcon.trailingAnchor, constant: 4),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: settingsButton.leadingAnchor, constant: -4),

            settingsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            settingsButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 20),
            settingsButton.heightAnchor.constraint(equalToConstant: 20),
        ])
    }

    // MARK: - Drawing

    var isActive = false { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath()
        path.appendRoundedRect(bounds, xRadius: 10, yRadius: 10)
        let bgAlpha: CGFloat = isActive ? 0.12 : 0.06
        NSColor.white.withAlphaComponent(bgAlpha).setFill()
        path.fill()

        NSColor.white.withAlphaComponent(0.1).setStroke()
        let line = NSBezierPath()
        line.move(to: NSPoint(x: 8, y: 0))
        line.line(to: NSPoint(x: bounds.width - 8, y: 0))
        line.lineWidth = 0.5
        line.stroke()
    }

    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // MARK: - Double-Click to Edit

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            let local = convert(event.locationInWindow, from: nil)
            if titleLabel.frame.contains(local) {
                enableEditing()
            } else {
                onDoubleClickBackground?()
            }
        } else {
            super.mouseDown(with: event)
        }
    }

    private func enableEditing() {
        titleLabel.wantsLayer = true
        titleLabel.isEditable = true
        titleLabel.isSelectable = true
        titleLabel.backgroundColor = NSColor.white.withAlphaComponent(0.15)
        titleLabel.layer?.cornerRadius = 4
        window?.makeFirstResponder(titleLabel)
        titleLabel.selectText(nil)
    }

    func cancelEditing() {
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.backgroundColor = .clear
        titleLabel.stringValue = config.title
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidEndEditing(_ obj: Notification) {
        let newTitle = titleLabel.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.backgroundColor = .clear

        if !newTitle.isEmpty && newTitle != config.title {
            config.title = newTitle
            onTitleChanged?(newTitle)
        } else {
            titleLabel.stringValue = config.title
        }
    }

    // MARK: - Public

    func updateTitle(_ title: String) {
        config.title = title
        titleLabel.stringValue = config.displayTitle
        lockIcon.isHidden = !config.isLocked
    }

    func updateConfig(_ config: PanelConfig) {
        self.config = config
        titleLabel.stringValue = config.displayTitle
        lockIcon.isHidden = !config.isLocked
    }

    @objc private func settingsClicked() {
        onSettingsClicked?()
    }
}
