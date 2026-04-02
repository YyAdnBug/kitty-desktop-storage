import Foundation
import Combine

final class GlobalPreferences: ObservableObject {
    static let shared = GlobalPreferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let alwaysOnTop = "alwaysOnTop"
        static let launchAtLogin = "launchAtLogin"
        static let showInAllSpaces = "showInAllSpaces"
    }

    @Published var alwaysOnTop: Bool {
        didSet {
            defaults.set(alwaysOnTop, forKey: Keys.alwaysOnTop)
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        }
    }

    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    @Published var showInAllSpaces: Bool {
        didSet {
            defaults.set(showInAllSpaces, forKey: Keys.showInAllSpaces)
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        }
    }

    private init() {
        self.alwaysOnTop = defaults.bool(forKey: Keys.alwaysOnTop)  // default: false
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)

        if defaults.object(forKey: Keys.showInAllSpaces) == nil {
            defaults.set(true, forKey: Keys.showInAllSpaces)
        }
        self.showInAllSpaces = defaults.bool(forKey: Keys.showInAllSpaces)
    }
}

extension Notification.Name {
    static let preferencesDidChange = Notification.Name("com.kitty.desktop.preferencesDidChange")
}
