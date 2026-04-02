import AppKit

final class FileGridView: NSView, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {

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
        config.items.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let cell = collectionView.makeItem(withIdentifier: FileGridItem.identifier, for: indexPath) as! FileGridItem
        let item = config.items[indexPath.item]
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

    // MARK: - Delete Key

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 51 || event.keyCode == 117 {
            let selected = collectionView.selectionIndexPaths
            guard !selected.isEmpty else { return }

            let items = selected.compactMap { indexPath -> PanelItem? in
                guard indexPath.item < config.items.count else { return nil }
                return config.items[indexPath.item]
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
}
