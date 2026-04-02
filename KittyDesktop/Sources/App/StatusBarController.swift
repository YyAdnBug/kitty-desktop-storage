import AppKit

final class StatusBarController {

    private var statusItem: NSStatusItem!

    init() {
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            let icon: NSImage?
            if let path = Bundle.main.path(forResource: "menubar_icon", ofType: "png") {
                icon = NSImage(contentsOfFile: path)
                NSLog("[KittyDesktop] Loaded icon from bundle path: \(path)")
            } else {
                icon = NSImage(named: "MenuBarIcon")
                NSLog("[KittyDesktop] Tried NSImage(named:), result: \(icon != nil)")
            }

            if let icon = icon {
                icon.size = NSSize(width: 18, height: 18)
                button.image = icon
            } else {
                NSLog("[KittyDesktop] WARNING: No icon found, using emoji fallback")
                button.title = "🐱"
            }
        }

        statusItem.menu = buildMenu()
        NSLog("[KittyDesktop] StatusItem menu set")
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

        let showAll = NSMenuItem(
            title: "显示所有面板",
            action: #selector(AppDelegate.showAllPanels),
            keyEquivalent: ""
        )
        menu.addItem(showAll)

        let hideAll = NSMenuItem(
            title: "隐藏所有面板",
            action: #selector(AppDelegate.hideAllPanels),
            keyEquivalent: ""
        )
        menu.addItem(hideAll)

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
