import AppKit

NSLog("[KittyDesktop] main.swift: starting")

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate

NSLog("[KittyDesktop] main.swift: calling app.run()")
app.run()
