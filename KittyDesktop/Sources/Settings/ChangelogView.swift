import SwiftUI

struct ChangelogEntry: Identifiable {
    let id = UUID()
    let version: String
    let build: String
    let date: String
    let items: [ChangeItem]
}

struct ChangeItem: Identifiable {
    let id = UUID()
    let type: ChangeType
    let text: String
}

enum ChangeType: String {
    case added = "新增"
    case fixed = "修复"
    case improved = "优化"
    case removed = "移除"

    var color: Color {
        switch self {
        case .added: return .green
        case .fixed: return .red
        case .improved: return .blue
        case .removed: return .gray
        }
    }
}

struct ChangelogView: View {

    static let entries: [ChangelogEntry] = [
        ChangelogEntry(
            version: "1.0.0", build: "9", date: "2026-04-03",
            items: [
                ChangeItem(type: .fixed, text: "Quick Look 空格键预览现在正常工作"),
                ChangeItem(type: .added, text: "面板内文件排序（按名称/类型/添加日期）"),
                ChangeItem(type: .added, text: "双击标题栏折叠/展开面板（双击文字仍可编辑）"),
                ChangeItem(type: .added, text: "面板布局导入/导出（JSON 格式备份与恢复）"),
                ChangeItem(type: .improved, text: "文件缩略图优化：图片、PDF 等显示真实预览"),
            ]
        ),
        ChangelogEntry(
            version: "1.0.0", build: "8", date: "2026-04-03",
            items: [
                ChangeItem(type: .added, text: "全局热键 ⌥⌘D 一键显示/隐藏所有面板"),
                ChangeItem(type: .added, text: "Quick Look 预览：选中文件按空格键预览"),
                ChangeItem(type: .added, text: "面板锁定：防止误拖动/误调整大小"),
                ChangeItem(type: .added, text: "标题栏显示文件数量角标，如「工作（12）」"),
                ChangeItem(type: .added, text: "从面板拖出文件到 Finder 或其他应用"),
            ]
        ),
        ChangelogEntry(
            version: "1.0.0", build: "7", date: "2026-04-03",
            items: [
                ChangeItem(type: .added, text: "开机自动启动功能（SMAppService）"),
                ChangeItem(type: .added, text: "偏好设置中新增「更新日志」按钮"),
                ChangeItem(type: .improved, text: "隐藏原文件功能：开关切换时立即对所有面板已有文件生效"),
                ChangeItem(type: .improved, text: "App 启动时自动同步隐藏状态"),
                ChangeItem(type: .fixed, text: "已存在面板的文件开启隐藏后不生效"),
            ]
        ),
        ChangelogEntry(
            version: "1.0.0", build: "5", date: "2026-04-02",
            items: [
                ChangeItem(type: .added, text: "拖入面板后可隐藏原始文件（设置中开启）"),
                ChangeItem(type: .added, text: "单个面板可独立设置「置顶显示」"),
                ChangeItem(type: .added, text: "选中面板高亮边框"),
                ChangeItem(type: .improved, text: "点击面板内容区域即可激活（无需双击）"),
                ChangeItem(type: .improved, text: "贴边折叠/展开动画更流畅，修复快速进出闪烁"),
                ChangeItem(type: .improved, text: "拖入文件失败时弹出提示"),
                ChangeItem(type: .fixed, text: "面板名称不允许为空"),
                ChangeItem(type: .fixed, text: "右键菜单「新建面板」可能不触发"),
                ChangeItem(type: .fixed, text: "修改透明度不再覆盖折叠状态的半透明效果"),
                ChangeItem(type: .fixed, text: "App Icon 512x512@2x 尺寸警告"),
            ]
        ),
        ChangelogEntry(
            version: "1.0.0", build: "1", date: "2026-04-01",
            items: [
                ChangeItem(type: .added, text: "桌面面板：创建多个可拖动、可调整大小的收纳区域"),
                ChangeItem(type: .added, text: "文件拖放：将文件和文件夹拖入面板管理"),
                ChangeItem(type: .added, text: "面板设置：改名、调整透明度、更换背景颜色"),
                ChangeItem(type: .added, text: "贴边收缩：拖到屏幕边缘自动折叠，悬停展开"),
                ChangeItem(type: .added, text: "右键菜单：打开、在 Finder 中显示、移除、删除"),
                ChangeItem(type: .added, text: "全局偏好：置顶显示、多桌面可见"),
                ChangeItem(type: .added, text: "DMG 打包脚本，自动递增构建号"),
            ]
        ),
    ]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("更新日志")
                    .font(.title2.bold())
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(Self.entries) { entry in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("v\(entry.version)")
                                    .font(.headline)
                                Text("build \(entry.build)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.12))
                                    .cornerRadius(4)
                                Spacer()
                                Text(entry.date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            ForEach(entry.items) { item in
                                HStack(alignment: .top, spacing: 8) {
                                    Text(item.type.rawValue)
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(item.type.color.opacity(0.8))
                                        .cornerRadius(4)
                                        .frame(width: 40)

                                    Text(item.text)
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        if entry.id != Self.entries.last?.id {
                            Divider()
                                .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.vertical, 16)
            }

            Divider()

            HStack {
                Spacer()
                Button("关闭") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(16)
        }
        .frame(width: 460, height: 480)
    }
}
