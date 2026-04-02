import AppKit

enum EdgeSnapper {

    static let collapsedThickness: CGFloat = 5.0
    static let snapThreshold: CGFloat = 20.0
    static let expandDelay: TimeInterval = 0.15
    static let collapseDelay: TimeInterval = 0.6

    // MARK: - Snap Detection

    static func snapIfNeeded(panel: FencePanel) {
        guard let screen = panel.screen ?? NSScreen.main else { return }
        let sf = screen.visibleFrame
        let wf = panel.frame

        var side: SnapSide?
        if wf.minX <= sf.minX + snapThreshold { side = .left }
        else if wf.maxX >= sf.maxX - snapThreshold { side = .right }
        else if wf.minY <= sf.minY + snapThreshold { side = .bottom }
        else if wf.maxY >= sf.maxY - snapThreshold { side = .top }

        if let side = side {
            panel.expandedFrame = wf
            panel.panelConfig.expandedFrame = CodableRect(wf)
            panel.panelConfig.snapSide = side
            panel.panelConfig.isCollapsed = true
            animateCollapse(panel: panel, to: side)
        } else {
            panel.panelConfig.snapSide = nil
            panel.panelConfig.isCollapsed = false
            panel.expandedFrame = nil
            panel.panelConfig.expandedFrame = nil
        }
    }

    // MARK: - Collapse

    static func animateCollapse(panel: FencePanel, to side: SnapSide) {
        guard let screen = panel.screen ?? NSScreen.main else { return }
        let sf = screen.visibleFrame
        let wf = panel.expandedFrame ?? panel.frame
        var target = wf

        switch side {
        case .left:
            target.origin.x = sf.minX
            target.size.width = collapsedThickness
        case .right:
            target.origin.x = sf.maxX - collapsedThickness
            target.size.width = collapsedThickness
        case .bottom:
            target.origin.y = sf.minY
            target.size.height = collapsedThickness
        case .top:
            target.origin.y = sf.maxY - collapsedThickness
            target.size.height = collapsedThickness
        }

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(target, display: true)
            panel.animator().alphaValue = 0.5
        } completionHandler: {
            panel.fencePanelView.installEdgeTracking(side: side)
        }
    }

    // MARK: - Expand

    static func animateExpand(panel: FencePanel) {
        guard let expandedFrame = panel.expandedFrame else { return }

        panel.fencePanelView.removeEdgeTracking()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(expandedFrame, display: true)
            panel.animator().alphaValue = CGFloat(panel.panelConfig.opacity)
        }
    }

    // MARK: - Instant (no animation, used for initial load)

    static func applyCollapsedFrame(to panel: FencePanel, side: SnapSide, animated: Bool) {
        guard let screen = panel.screen ?? NSScreen.main else { return }
        let sf = screen.visibleFrame
        let wf = panel.expandedFrame ?? panel.frame
        var target = wf

        switch side {
        case .left:
            target.origin.x = sf.minX
            target.size.width = collapsedThickness
        case .right:
            target.origin.x = sf.maxX - collapsedThickness
            target.size.width = collapsedThickness
        case .bottom:
            target.origin.y = sf.minY
            target.size.height = collapsedThickness
        case .top:
            target.origin.y = sf.maxY - collapsedThickness
            target.size.height = collapsedThickness
        }

        if animated {
            animateCollapse(panel: panel, to: side)
        } else {
            panel.setFrame(target, display: true)
            panel.alphaValue = 0.5
            panel.fencePanelView.installEdgeTracking(side: side)
        }
    }

    // MARK: - Unsnap (detach from edge)

    static func unsnap(panel: FencePanel) {
        panel.panelConfig.snapSide = nil
        panel.panelConfig.isCollapsed = false
        panel.panelConfig.expandedFrame = nil
        panel.fencePanelView.removeEdgeTracking()
        panel.expandedFrame = nil
    }
}

// MARK: - Edge Tracking Extensions on FencePanelView

extension FencePanelView {

    private nonisolated(unsafe) static var edgeTrackingAreaKey: UInt8 = 0

    func installEdgeTracking(side: SnapSide) {
        removeEdgeTracking()

        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: ["edge": side.rawValue]
        )
        addTrackingArea(area)
        objc_setAssociatedObject(self, &FencePanelView.edgeTrackingAreaKey, area, .OBJC_ASSOCIATION_RETAIN)
    }

    func removeEdgeTracking() {
        if let existing = objc_getAssociatedObject(self, &FencePanelView.edgeTrackingAreaKey) as? NSTrackingArea {
            removeTrackingArea(existing)
            objc_setAssociatedObject(self, &FencePanelView.edgeTrackingAreaKey, nil, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        guard let info = event.trackingArea?.userInfo,
              let sideRaw = info["edge"] as? String,
              let _ = SnapSide(rawValue: sideRaw) else {
            super.mouseEntered(with: event)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + EdgeSnapper.expandDelay) { [weak self] in
            guard let self, let window = self.window as? FencePanel else { return }
            guard window.panelConfig.isCollapsed else { return }
            window.panelConfig.isCollapsed = false
            EdgeSnapper.animateExpand(panel: window)
        }
    }

    override func mouseExited(with event: NSEvent) {
        guard let info = event.trackingArea?.userInfo,
              let sideRaw = info["edge"] as? String,
              let side = SnapSide(rawValue: sideRaw) else {
            super.mouseExited(with: event)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + EdgeSnapper.collapseDelay) { [weak self] in
            guard let self, let window = self.window as? FencePanel else { return }
            guard window.panelConfig.snapSide != nil else { return }
            let mouseLocation = NSEvent.mouseLocation
            if !window.frame.contains(mouseLocation) {
                window.panelConfig.isCollapsed = true
                EdgeSnapper.animateCollapse(panel: window, to: side)
            }
        }
    }
}
