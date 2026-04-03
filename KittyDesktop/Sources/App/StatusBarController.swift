import AppKit

final class StatusBarController {

    private var statusItem: NSStatusItem!

    init() {
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            if let path = Bundle.main.path(forResource: "menubar_icon", ofType: "png") {
                let icon = NSImage(contentsOfFile: path)
                icon?.size = NSSize(width: 18, height: 18)
                button.image = icon
            } else {
                button.title = "🐱"
            }
        }

        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "Kitty 桌面收纳", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(.separator())

        let newPanel = NSMenuItem(
            title: "新建面板",
            action: #selector(AppDelegate.createNewPanelFromMenu),
            keyEquivalent: "n"
        )
        newPanel.keyEquivalentModifierMask = [.command]
        menu.addItem(newPanel)

        menu.addItem(.separator())

        let toggleAll = NSMenuItem(
            title: "显示/隐藏所有面板",
            action: #selector(AppDelegate.toggleAllPanels),
            keyEquivalent: "d"
        )
        toggleAll.keyEquivalentModifierMask = [.option, .command]
        menu.addItem(toggleAll)

        menu.addItem(.separator())

        let unhideAll = NSMenuItem(
            title: "恢复所有隐藏文件",
            action: #selector(AppDelegate.unhideAllFiles),
            keyEquivalent: ""
        )
        menu.addItem(unhideAll)

        menu.addItem(.separator())

        let prefs = NSMenuItem(
            title: "偏好设置…",
            action: #selector(AppDelegate.showPreferences),
            keyEquivalent: ","
        )
        prefs.keyEquivalentModifierMask = [.command]
        menu.addItem(prefs)

        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: "退出 Kitty 桌面收纳",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quit.keyEquivalentModifierMask = [.command]
        menu.addItem(quit)

        return menu
    }
}
