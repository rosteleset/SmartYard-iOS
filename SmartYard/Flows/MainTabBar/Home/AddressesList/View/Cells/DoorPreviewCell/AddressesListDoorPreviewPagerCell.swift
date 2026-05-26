//
//  AddressesListDoorPreviewPagerCell.swift
//  SmartYard
//
//  Created by Александр Попов on 21.04.2026.
//

import UIKit
import RxRelay
import RxSwift
import SnapKit

final class AddressesListDoorPreviewPagerCell: CustomBorderCollectionViewCell, HasDisposeBag {

    private let flowLayout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    private let pageControl = UIPageControl()

    let openRequested = PublishRelay<AddressesListDataItemIdentity>()
    let previewSelected = PublishRelay<AddressesListDataItemIdentity>()

    private var items: [AddressesListDoorPreviewItem] = []
    private var currentItemIdentity: AddressesListDataItemIdentity?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.layer.cornerRadius = layer.cornerRadius
        contentView.layer.maskedCorners = layer.maskedCorners

        let itemSize = collectionView.bounds.size
        guard itemSize.width > 0, itemSize.height > 0 else {
            return
        }

        if flowLayout.itemSize != itemSize {
            flowLayout.itemSize = itemSize
            flowLayout.invalidateLayout()
            setCurrentPage(pageControl.currentPage)
            scrollToCurrentPage(animated: false)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        resetDisposeBag()
    }

    func configure(
        items: [AddressesListDoorPreviewItem],
        selectedIdentity: AddressesListDataItemIdentity?
    ) {
        let currentPage = page(for: selectedIdentity ?? currentItemIdentity, in: items)

        self.items = items

        pageControl.numberOfPages = items.count
        collectionView.isScrollEnabled = items.count > 1

        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        setCurrentPage(currentPage)
        scrollToCurrentPage(animated: false)
    }

    func select(identity: AddressesListDataItemIdentity, animated: Bool) {
        let selectedPage = page(for: identity, in: items)
        guard items.indices.contains(selectedPage),
              items[selectedPage].identity == identity
        else {
            return
        }

        setCurrentPage(selectedPage)
        scrollToCurrentPage(animated: animated)
    }
}

private extension AddressesListDoorPreviewPagerCell {
    func configureUI() {
        setupUI()
        setupConstraints()
    }

    // MARK: - Setup UI

    func setupUI() {
        backgroundColor = .SmartYard.secondBackgroundColor
        contentView.backgroundColor = .SmartYard.secondBackgroundColor
        contentView.clipsToBounds = true

        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.decelerationRate = .fast
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(cellWithClass: AddressesListDoorPreviewCell.self)

        pageControl.currentPageIndicatorTintColor = .white
        pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.35)
        pageControl.hidesForSinglePage = true
        pageControl.isUserInteractionEnabled = false
        pageControl.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
    }

    // MARK: - Setup Constraints

    func setupConstraints() {
        contentView.pinSubview(collectionView)

        contentView.addSubview(pageControl) { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(10)
        }
    }

    func page(for identity: AddressesListDataItemIdentity?, in items: [AddressesListDoorPreviewItem]) -> Int {
        guard let identity,
              let page = items.firstIndex(where: { $0.identity == identity })
        else {
            return 0
        }

        return page
    }

    func setCurrentPage(_ page: Int) {
        let maxPage = max(items.count - 1, 0)
        let currentPage = min(max(page, 0), maxPage)

        pageControl.currentPage = currentPage
        currentItemIdentity = items.indices.contains(currentPage) ? items[currentPage].identity : nil
    }

    func scrollToCurrentPage(animated: Bool) {
        guard collectionView.bounds.width > 0 else {
            return
        }

        collectionView.setContentOffset(
            CGPoint(x: CGFloat(pageControl.currentPage) * collectionView.bounds.width, y: 0),
            animated: animated
        )
    }
}

extension AddressesListDoorPreviewPagerCell: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withClass: AddressesListDoorPreviewCell.self,
            for: indexPath
        )

        let item = items[indexPath.item]
        cell.configure(
            title: item.title,
            subtitle: item.subtitle,
            previewSource: item.previewSource,
            hasCamera: item.hasCamera,
            isOpened: item.isOpened
        )

        let openSubject = PublishSubject<Void>()
        openSubject
            .do(onNext: { [weak self] in
                self?.currentItemIdentity = item.identity
            })
            .map { item.identity }
            .bind(to: openRequested)
            .disposed(by: cell.disposeBag)

        cell.bind(with: openSubject)
        return cell
    }
}

extension AddressesListDoorPreviewPagerCell: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard items.indices.contains(indexPath.item) else {
            return
        }

        currentItemIdentity = items[indexPath.item].identity
        previewSelected.accept(items[indexPath.item].identity)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return collectionView.bounds.size
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !items.isEmpty, collectionView.bounds.width > 0 else {
            return
        }

        let rawPage = scrollView.contentOffset.x / collectionView.bounds.width
        let page = Int(round(rawPage))
        setCurrentPage(page)
    }
}
