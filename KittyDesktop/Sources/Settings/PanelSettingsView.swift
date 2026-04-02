import SwiftUI

struct PanelSettingsView: View {
    @Binding var title: String
    @Binding var opacity: Float
    @Binding var backgroundColor: CodableColor
    @Binding var alwaysOnTop: Bool
    var onDismiss: () -> Void

    @State private var swiftUIColor: Color
    @State private var showTitleError = false

    init(title: Binding<String>, opacity: Binding<Float>, backgroundColor: Binding<CodableColor>, alwaysOnTop: Binding<Bool>, onDismiss: @escaping () -> Void) {
        self._title = title
        self._opacity = opacity
        self._backgroundColor = backgroundColor
        self._alwaysOnTop = alwaysOnTop
        self.onDismiss = onDismiss
        let c = backgroundColor.wrappedValue
        self._swiftUIColor = State(initialValue: Color(
            red: Double(c.red),
            green: Double(c.green),
            blue: Double(c.blue),
            opacity: Double(c.alpha)
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("面板设置")
                .font(.headline)

            Divider()

            // Title
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("名称")
                        .frame(width: 60, alignment: .leading)
                    TextField("面板名称", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: title) { newVal in
                            showTitleError = newVal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        }
                }
                if showTitleError {
                    Text("面板名称不能为空")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.leading, 64)
                }
            }

            // Opacity
            HStack {
                Text("透明度")
                    .frame(width: 60, alignment: .leading)
                Slider(value: $opacity, in: 0.15...1.0, step: 0.05)
                Text("\(Int(opacity * 100))%")
                    .frame(width: 40)
                    .foregroundColor(.secondary)
            }

            // Color
            HStack {
                Text("颜色")
                    .frame(width: 60, alignment: .leading)
                ColorPicker("", selection: $swiftUIColor, supportsOpacity: true)
                    .labelsHidden()
                    .onChange(of: swiftUIColor) { newColor in
                        if let components = NSColor(newColor).usingColorSpace(.deviceRGB) {
                            backgroundColor = CodableColor(
                                red: components.redComponent,
                                green: components.greenComponent,
                                blue: components.blueComponent,
                                alpha: components.alphaComponent
                            )
                        }
                    }
            }

            // Preset colors
            VStack(alignment: .leading, spacing: 4) {
                Text("预设")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    ForEach(0..<CodableColor.presets.count, id: \.self) { i in
                        let preset = CodableColor.presets[i]
                        Circle()
                            .fill(Color(
                                red: Double(preset.red),
                                green: Double(preset.green),
                                blue: Double(preset.blue),
                                opacity: Double(preset.alpha)
                            ))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .onTapGesture {
                                backgroundColor = preset
                                swiftUIColor = Color(
                                    red: Double(preset.red),
                                    green: Double(preset.green),
                                    blue: Double(preset.blue),
                                    opacity: Double(preset.alpha)
                                )
                            }
                    }
                }
            }

            // Always on top
            Toggle(isOn: $alwaysOnTop) {
                HStack {
                    Text("置顶显示")
                        .frame(width: 60, alignment: .leading)
                    Text("此面板始终显示在其他窗口上方")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)

            Divider()

            HStack {
                Spacer()
                Button("完成") {
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 300)
    }
}

// MARK: - Hosting Controller

final class PanelSettingsHostingController {

    private var popover: NSPopover?

    func show(for panel: FencePanel, relativeTo view: NSView) {
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true

        var title = panel.panelConfig.title
        var opacity = panel.panelConfig.opacity
        var bgColor = panel.panelConfig.backgroundColor
        var onTop = panel.panelConfig.alwaysOnTop

        let settingsView = PanelSettingsView(
            title: .init(get: { title }, set: { newVal in
                title = newVal
                let trimmed = newVal.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                panel.panelConfig.title = trimmed
                panel.applyConfigChanges()
                panel.panelDelegate?.panelDidUpdateConfig(panel)
            }),
            opacity: .init(get: { opacity }, set: { newVal in
                opacity = newVal
                panel.panelConfig.opacity = newVal
                panel.applyConfigChanges()
                panel.panelDelegate?.panelDidUpdateConfig(panel)
            }),
            backgroundColor: .init(get: { bgColor }, set: { newVal in
                bgColor = newVal
                panel.panelConfig.backgroundColor = newVal
                panel.applyConfigChanges()
                panel.panelDelegate?.panelDidUpdateConfig(panel)
            }),
            alwaysOnTop: .init(get: { onTop }, set: { newVal in
                onTop = newVal
                panel.panelConfig.alwaysOnTop = newVal
                panel.applyConfigChanges()
                panel.panelDelegate?.panelDidUpdateConfig(panel)
            }),
            onDismiss: { [weak popover] in
                popover?.close()
            }
        )

        popover.contentViewController = NSHostingController(rootView: settingsView)
        popover.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        self.popover = popover
    }

    func close() {
        popover?.close()
        popover = nil
    }
}
