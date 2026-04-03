import Foundation
import Combine
import ServiceManagement

final class GlobalPreferences: ObservableObject {
    static let shared = GlobalPreferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let alwaysOnTop = "alwaysOnTop"
        static let showInAllSpaces = "showInAllSpaces"
        static let hideOriginalAfterAdd = "hideOriginalAfterAdd"
    }

    @Published var alwaysOnTop: Bool {
        didSet {
            defaults.set(alwaysOnTop, forKey: Keys.alwaysOnTop)
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("[KittyDesktop] SMAppService error: \(error)")
                launchAtLogin = !launchAtLogin
            }
        }
    }

    @Published var showInAllSpaces: Bool {
        didSet {
            defaults.set(showInAllSpaces, forKey: Keys.showInAllSpaces)
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        }
    }

    @Published var hideOriginalAfterAdd: Bool {
        didSet {
            defaults.set(hideOriginalAfterAdd, forKey: Keys.hideOriginalAfterAdd)
            if hideOriginalAfterAdd {
                FileHideManager.shared.hideAllManagedFiles()
            } else {
                FileHideManager.shared.unhideAllManagedFiles()
            }
        }
    }

    private init() {
        self.alwaysOnTop = defaults.bool(forKey: Keys.alwaysOnTop)
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        self.hideOriginalAfterAdd = defaults.bool(forKey: Keys.hideOriginalAfterAdd)

        if defaults.object(forKey: Keys.showInAllSpaces) == nil {
            defaults.set(true, forKey: Keys.showInAllSpaces)
        }
        self.showInAllSpaces = defaults.bool(forKey: Keys.showInAllSpaces)
    }
}

extension Notification.Name {
    static let preferencesDidChange = Notification.Name("com.kitty.desktop.preferencesDidChange")
}
