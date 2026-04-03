import AppKit
import SwiftUI

final class PreferencesWindowController {
    private var window: NSWindow?

    func showWindow() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let prefsView = PreferencesContentView()
        let hostingController = NSHostingController(rootView: prefsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Kitty 桌面收纳 - 偏好设置"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 400, height: 360))
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        window?.close()
    }
}

struct PreferencesContentView: View {
    @ObservedObject private var prefs = GlobalPreferences.shared
    @State private var showChangelog = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 10) {
                if let icon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 48, height: 48)
                }
                VStack(alignment: .leading) {
                    Text("Kitty 桌面收纳")
                        .font(.title2.bold())
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("更新日志") { showChangelog = true }
                    .controlSize(.small)
            }
            .padding(.bottom, 16)

            Divider()
                .padding(.bottom, 16)

            // Settings
            VStack(alignment: .leading, spacing: 14) {
                Toggle(isOn: $prefs.alwaysOnTop) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("置顶显示")
                            .font(.body)
                        Text("面板始终显示在其他窗口上方")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)

                Toggle(isOn: $prefs.showInAllSpaces) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("所有桌面空间可见")
                            .font(.body)
                        Text("面板在所有 Space / 桌面中显示")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)

                Toggle(isOn: $prefs.hideOriginalAfterAdd) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("拖入后隐藏原文件")
                            .font(.body)
                        Text("文件拖入面板后，在原位置隐藏（从面板移除后自动恢复）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)

                Toggle(isOn: $prefs.launchAtLogin) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("开机自动启动")
                            .font(.body)
                        Text("登录后自动运行 Kitty 桌面收纳")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }

            Spacer()

            Divider()
                .padding(.vertical, 12)

            HStack {
                Spacer()
                Text("面板默认在桌面层级，不遮挡其他窗口")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(24)
        .frame(width: 400, height: 360)
        .sheet(isPresented: $showChangelog) {
            ChangelogView()
        }
    }
}
