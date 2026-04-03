import AppKit
import Quartz

final class FileGridView: NSView, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, QLPreviewPanelDataSource, QLPreviewPanelDelegate {

    private var collectionView: NSCollectionView!
    private var scrollView: NSScrollView!
    private var config: PanelConfig
    private let itemSize = NSSize(width: 72, height: 80)

    var onItemRemoved: ((PanelItem) -> Void)?
    var onItemTrashed: ((PanelItem) -> Void)?

    init(config: PanelConfig) {
        self.config = config
        super.init(frame: .zero)
        setupCollectionView()
        NotificationCenter.default.addObserver(self, selector: #selector(thumbnailLoaded),
                                               name: .thumbnailDidLoad, object: nil)
    }

    @objc private func thumbnailLoaded() {
        collectionView.reloadData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupCollectionView() {
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = itemSize
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        layout.sectionInset = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        collectionView = NSCollectionView()
        collectionView.collectionViewLayout = layout
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isSelectable = true
        collectionView.allowsMultipleSelection = false
        collectionView.backgroundColors = [.clear]
        collectionView.register(FileGridItem.self, forItemWithIdentifier: FileGridItem.identifier)

        scrollView = NSScrollView()
        scrollView.documentView = collectionView
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - Public

    func reloadData(with config: PanelConfig) {
        self.config = config
        collectionView.reloadData()
    }

    // MARK: - NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        config.sortedItems.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let cell = collectionView.makeItem(withIdentifier: FileGridItem.identifier, for: indexPath) as! FileGridItem
        let sorted = config.sortedItems
        let item = sorted[indexPath.item]
        cell.configure(with: item)

        cell.onRemoveFromPanel = { [weak self] panelItem in
            self?.onItemRemoved?(panelItem)
        }
        cell.onMoveToTrash = { [weak self] panelItem in
            self?.onItemTrashed?(panelItem)
        }
        cell.onRevealInFinder = { panelItem in
            TrashHandler.revealInFinder(item: panelItem)
        }
        return cell
    }

    // MARK: - NSCollectionViewDelegate

    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        // Selection highlight handled by FileGridItem.isSelected
    }

    // MARK: - Keyboard Events

    override func keyDown(with event: NSEvent) {
        // Delete / Backspace
        if event.keyCode == 51 || event.keyCode == 117 {
            let selected = collectionView.selectionIndexPaths
            guard !selected.isEmpty else { return }

            let sorted = config.sortedItems
            let items = selected.compactMap { indexPath -> PanelItem? in
                guard indexPath.item < sorted.count else { return nil }
                return sorted[indexPath.item]
            }
            guard !items.isEmpty else { return }

            for item in items {
                onItemRemoved?(item)
            }
        } else {
            super.keyDown(with: event)
        }
    }

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // MARK: - Quick Look

    private var previewItems: [QLPreviewItem] = []

    func toggleQuickLook() {
        guard let qlPanel = QLPreviewPanel.shared() else { return }
        if qlPanel.isVisible {
            qlPanel.orderOut(nil)
            return
        }

        let sorted = config.sortedItems
        let selected = collectionView.selectionIndexPaths
            .sorted { $0.item < $1.item }
            .compactMap { ip -> URL? in
                guard ip.item < sorted.count else { return nil }
                return sorted[ip.item].resolveURL()
            }
        guard !selected.isEmpty else { return }
        previewItems = selected.map { $0 as NSURL }
        qlPanel.dataSource = self
        qlPanel.delegate = self
        qlPanel.reloadData()
        qlPanel.makeKeyAndOrderFront(nil)
    }

    override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool { true }
    override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) { panel.dataSource = self; panel.delegate = self }
    override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {}

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        previewItems.count
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
        previewItems[index]
    }
}
