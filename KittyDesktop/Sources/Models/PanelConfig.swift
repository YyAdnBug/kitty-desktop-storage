import Foundation

enum SnapSide: String, Codable {
    case left, right, top, bottom
}

enum SortOrder: String, Codable {
    case manual = "手动"
    case byName = "按名称"
    case byType = "按类型"
    case byDateAdded = "按添加日期"
}

struct CodableRect: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    var nsRect: NSRect {
        NSRect(x: x, y: y, width: width, height: height)
    }

    init(_ rect: CGRect) {
        self.x = rect.origin.x
        self.y = rect.origin.y
        self.width = rect.size.width
        self.height = rect.size.height
    }

    init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

struct PanelConfig: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var opacity: Float
    var backgroundColor: CodableColor
    var frame: CodableRect
    var expandedFrame: CodableRect?
    var snapSide: SnapSide?
    var items: [PanelItem]
    var isCollapsed: Bool
    var isFolded: Bool
    var alwaysOnTop: Bool
    var isLocked: Bool
    var sortOrder: SortOrder
    var createdDate: Date

    var displayTitle: String {
        items.isEmpty ? title : "\(title)（\(items.count)）"
    }

    var sortedItems: [PanelItem] {
        switch sortOrder {
        case .manual:
            return items
        case .byName:
            return items.sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
        case .byType:
            return items.sorted {
                let ext0 = ($0.resolveURL()?.pathExtension ?? "").lowercased()
                let ext1 = ($1.resolveURL()?.pathExtension ?? "").lowercased()
                if ext0 == ext1 { return $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
                return ext0 < ext1
            }
        case .byDateAdded:
            return items.sorted { $0.addedDate < $1.addedDate }
        }
    }

    static let minWidth: CGFloat = 150
    static let minHeight: CGFloat = 100
    static let titleBarHeight: CGFloat = 28
    static let defaultWidth: CGFloat = 280
    static let defaultHeight: CGFloat = 320

    init(title: String, frame: CGRect) {
        self.id = UUID()
        self.title = title
        self.opacity = 0.85
        self.backgroundColor = .defaultBackground
        self.frame = CodableRect(frame)
        self.expandedFrame = nil
        self.snapSide = nil
        self.items = []
        self.isCollapsed = false
        self.isFolded = false
        self.alwaysOnTop = false
        self.isLocked = false
        self.sortOrder = .manual
        self.createdDate = Date()
    }

    static func == (lhs: PanelConfig, rhs: PanelConfig) -> Bool {
        lhs.id == rhs.id
    }

    enum CodingKeys: String, CodingKey {
        case id, title, opacity, backgroundColor, frame, expandedFrame
        case snapSide, items, isCollapsed, isFolded, alwaysOnTop, isLocked, sortOrder, createdDate
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        opacity = try c.decode(Float.self, forKey: .opacity)
        backgroundColor = try c.decode(CodableColor.self, forKey: .backgroundColor)
        frame = try c.decode(CodableRect.self, forKey: .frame)
        expandedFrame = try c.decodeIfPresent(CodableRect.self, forKey: .expandedFrame)
        snapSide = try c.decodeIfPresent(SnapSide.self, forKey: .snapSide)
        items = try c.decode([PanelItem].self, forKey: .items)
        isCollapsed = try c.decode(Bool.self, forKey: .isCollapsed)
        isFolded = try c.decodeIfPresent(Bool.self, forKey: .isFolded) ?? false
        alwaysOnTop = try c.decodeIfPresent(Bool.self, forKey: .alwaysOnTop) ?? false
        isLocked = try c.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
        sortOrder = try c.decodeIfPresent(SortOrder.self, forKey: .sortOrder) ?? .manual
        createdDate = try c.decode(Date.self, forKey: .createdDate)
    }
}
