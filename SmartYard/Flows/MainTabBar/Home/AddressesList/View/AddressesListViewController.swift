//
//  AddressesViewController.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import JGProgressHUD
import SkeletonView
import SnapKit
import SwifterSwift

private enum StoriesLayout {
    static let headerTopOffset: CGFloat = 8
    static let topOffset: CGFloat = 18
    static let height: CGFloat = 120
    static let bottomOffset: CGFloat = 18
    static let itemWidth: CGFloat = 88
    static let lineSpacing: CGFloat = 12
    static let horizontalInset: CGFloat = 16
    static let addButtonTrailingOffset: CGFloat = 16
    static let addButtonSize: CGFloat = 44

    static var mainContainerTopOffset: CGFloat {
        topOffset + height + bottomOffset
    }
}

// swiftlint:disable:next type_body_length
final class AddressesListViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var headerView: UILabel!
    @IBOutlet private weak var mainContainerView: UIView!
    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var skeletonContainer: UIView!
    
    private let storiesFlowLayout = UICollectionViewFlowLayout()
    private lazy var storiesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: storiesFlowLayout)
    private var storiesHeightConstraint: Constraint?
    private weak var mainContainerTopConstraint: NSLayoutConstraint?
    private weak var headerTopConstraint: NSLayoutConstraint?
    private weak var addButtonTrailingConstraint: NSLayoutConstraint?
    private var addButtonSizeConstraints: [NSLayoutConstraint] = []
    private var defaultOffsets = (headerTop: CGFloat(0), mainTop: CGFloat(0), addTrailing: CGFloat(0), addSize: CGFloat(0))

    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<AddressesListSectionModel>?
    private var storiesDataSource: RxCollectionViewSectionedReloadDataSource<SectionModel<String, StoryItemCellModel>>?
    private var refreshControl = UIRefreshControl()
    
    // MARK: Это костыль для того, чтобы понять, сколько на самом деле ячеек внутри секции
    // В методе configureCell у RxDataSource мы должны сконфигурировать ячейку
    // Но проблема в том, что RxDataSource выполняет операции обновления и добавления ячеек отдельно
    // Сначала выполняется обновление уже существующих ячеек, а потом добавляются новые
    // Поэтому на момент обновления ячеек мы не можем получить актуальное количество секций через dataSource[section]
    // Так что приходится проксировать количество ячеек в секциях в отдельный субъект и брать данные отсюда
    
    private let itemsCountProxy = BehaviorSubject<[Int: Int]>(value: [:])
    
    private let viewModel: AddressesListViewModel

    private let requestGuestAccess = PublishSubject<AddressesListDataItemIdentity>()
    private let previewSelected = PublishSubject<AddressesListDataItemIdentity>()
    private let qrCodeTapped = PublishSubject<Void>()
    private var selectedDoorPreviewIdentityByAddressId: [String: AddressesListDataItemIdentity] = [:]
    
    var loader: JGProgressHUD?
    
    init(viewModel: AddressesListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureCollectionView()
        configureStoriesDataSource()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if skeletonContainer.sk.isSkeletonActive {
            skeletonContainer.showSkeletonAsynchronously(with: UIColor.SmartYard.secondBackgroundColor)
        }
    }
    
    // swiftlint:disable:next function_body_length
    private func bind() {
        let itemSelected = Driver.merge(
            collectionView.rx.itemSelected
                .map { [weak self] indexPath in
                    self?.dataSource?[indexPath].identity
                }
                .ignoreNil()
                .asDriverOnErrorJustComplete(),
            previewSelected.asDriverOnErrorJustComplete()
        )
        
        let input = AddressesListViewModel.Input(
            itemSelected: itemSelected,
            storySelected: storiesCollectionView.rx.itemSelected
                .map(\.item)
                .asDriverOnErrorJustComplete(),
            guestAccessRequested: requestGuestAccess.asDriverOnErrorJustComplete(),
            refreshDataTrigger: refreshControl.rx.controlEvent(.valueChanged).asDriver(),
            addAddressTrigger: addButton.rx.tap.asDriver(),
            issueQrCodeTrigger: qrCodeTapped.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        // MARK: При получении моделей сначала проксируем словарь с количеством ячеек в секциях
        // А уже потом отправляем свежие модели в таблицу
        
        output.sectionModels
            .do(
                onNext: { [weak self] models in
                    let itemsCountDict: [Int: Int] = models.enumerated().reduce([:]) { dict, enumeration in
                        let (offset, element) = enumeration
                        
                        var mutableDict = dict
                        mutableDict[offset] = element.items.count
                        return mutableDict
                    }
                    
                    self?.itemsCountProxy.onNext(itemsCountDict)
                }
            )
            .drive(collectionView.rx.items(dataSource: dataSource!))
            .disposed(by: disposeBag)

        output.storyCellModels
            .do(onNext: { [weak self] models in self?.updateStoriesVisibility(hasStories: !models.isEmpty) })
            .map { [SectionModel(model: "stories", items: $0)] }
            .drive(storiesCollectionView.rx.items(dataSource: storiesDataSource!))
            .disposed(by: disposeBag)

        output.reloadingFinished
            .drive(
                onNext: { [weak self] in
                    self?.refreshControl.endRefreshing()
                }
            )
            .disposed(by: disposeBag)

        bindSelectedDoorPreviewIdentity(output)
        
        // MARK: Скроллим таблицу при сворачивании / разворачивании секций для лучшего UX
        
        let updateKindSubject = BehaviorSubject<AddressesListSectionUpdateKind?>(value: nil)
        let updateKind = updateKindSubject.asDriver(onErrorJustReturn: nil)
        
        output.updateKind
            .drive(
                onNext: {
                    updateKindSubject.onNext($0)
                }
            )
            .disposed(by: disposeBag)
        
        collectionView.rx
            .observeWeakly(CGSize.self, "contentSize", options: [.new])
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            
            // MARK: BatchUpdates проходят постепенно, поэтому contentSize меняется несколько раз
            // Чтобы анимации не конфликтовали, ждем, пока contentSize станет стабильным
            
            .debounce(.milliseconds(50))
            .withLatestFrom(updateKind)
            .ignoreNil()
            .do(
                onNext: { _ in
                    updateKindSubject.onNext(nil)
                }
            )
            .withLatestFrom(output.sectionModels) { ($0, $1) }
            
            // MARK: Ищем секцию, которая содержит Header с указанным идентификатором, и скроллим к нему
            
            .map { [weak self] updateKind, sectionModels -> (AddressesListSectionUpdateKind, IndexPath)? in
                let neededSectionOffset = sectionModels.enumerated().first { _, model in
                    model.items.contains { $0.identity == updateKind.associatedIdentity }
                }?.offset
                
                guard let section = neededSectionOffset else { return nil }

                guard !(self?.collectionView.refreshControl?.isRefreshing ?? false) else {
                    return nil
                }
                
                let indexPath = IndexPath(row: 0, section: section)
                return (updateKind, indexPath)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] updateKind, indexPath in
                    self?.performScrollUpdate(updateKind: updateKind, to: indexPath)
                }
            )
            .disposed(by: disposeBag)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    if isLoading {
                        self?.view.endEditing(true)
                    }
                    
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
        
        output.shouldBlockInteraction
            .drive(
                onNext: { [weak self] shouldBlockInteraction in
                    self?.collectionView.isHidden = shouldBlockInteraction
                    self?.skeletonContainer.isHidden = !shouldBlockInteraction
                    
                    shouldBlockInteraction ?
                        self?.skeletonContainer.showSkeletonAsynchronously(with: UIColor.SmartYard.backgroundColor) :
                        self?.skeletonContainer.hideSkeleton()
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func performScrollUpdate(
        updateKind: AddressesListSectionUpdateKind,
        to indexPath: IndexPath
    ) {
        switch updateKind {
        case .expand:
            guard
                let attributes = collectionView.collectionViewLayout.layoutAttributesForItem(at: indexPath)
            else {
                return
            }
            
            let contentHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
            
            let topInset = collectionView(
                collectionView,
                layout: collectionView.collectionViewLayout,
                insetForSectionAt: indexPath.section
            ).top
            
            let desiredOffset = attributes.frame.origin.y - topInset
            let maxPossibleOffset = contentHeight - collectionView.bounds.height
            
            let finalOffset = max(min(desiredOffset, maxPossibleOffset), 0)
            
            collectionView.setContentOffset(
                CGPoint(x: 0, y: finalOffset),
                animated: true
            )
            
        case .collapse:
            collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
        }
    }

    private func configureUI() {
        headerView.text = L10n.Home.Addresses.title
        configureStoriesCollectionView()
        
        mainContainerView.layerCornerRadius = 24
        mainContainerView.layer.maskedCorners = .topCorners

        configureAddButton()
    }
    
    private func configureCollectionView() {
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true
        collectionView.refreshControl = refreshControl
        refreshControl.tintColor = UIColor.SmartYard.gray
        
        [
            AddressesListObjectCell.self,
            AddressesListCameraCell.self,
            AddressesListHistoryCell.self,
            AddressesListEmptyStateCell.self,
            UnapprovedObjectCell.self
        ].forEach {
            collectionView.register(nibWithCellClass: $0)
        }

        collectionView.register(cellWithClass: AddressesListDoorPreviewCell.self)
        collectionView.register(cellWithClass: AddressesListDoorPreviewPagerCell.self)
        collectionView.register(cellWithClass: AddressesListExtensionCell.self)
        collectionView.register(cellWithClass: AddressesHeaderCell.self)
        
        let dataSource = RxCollectionViewSectionedAnimatedDataSource<AddressesListSectionModel>(
            configureCell: { [weak self] _, collectionView, indexPath, item in
                guard let self = self else {
                    // MARK: я думал, мы сюда вообще никак не сможем попасть, но я еще никогда так не ошибался
                    // Из-за реактивщины этот датасорс может жить чуть дольше, чем этот контроллер
                    // Из-за того, что я возвращал UICollectionViewCell(), приложение падало с эксепшном
                    // Типа нельзя использовать ячейки без ReuseIdentifier в таком датасорсе
                    // Поэтому возвращаю рандомную ячейку. Все равно контроллер уже мертв, нам пофиг
                    
                    return collectionView.dequeueReusableCell(
                        withClass: AddressesHeaderCell.self,
                        for: indexPath
                    )
                }
                
                return self.configureCell(
                    collectionView: collectionView,
                    indexPath: indexPath,
                    item: item
                )
            }
        )
        
        collectionView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
        
        self.dataSource = dataSource
    }

    // swiftlint:disable:next function_body_length
    private func configureCell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        item: AddressesListDataItem
    ) -> UICollectionViewCell {
        if case .emptyState = item {
            let cell = collectionView.dequeueReusableCell(
                withClass: AddressesListEmptyStateCell.self,
                for: indexPath
            )
            cell.configure(with: .online)
            return cell
        }
        
        let customizableCell: CustomBorderCollectionViewCell = {
            switch item {
            case let .header(_, address, isExpanded):
                let cell = collectionView.dequeueReusableCell(
                    withClass: AddressesHeaderCell.self,
                    for: indexPath
                )
                cell.configure(address: address, isExpanded: isExpanded)
                return cell
                
            case let .object(_, type, name, isOpened):
                let cell = collectionView.dequeueReusableCell(
                    withClass: AddressesListObjectCell.self,
                    for: indexPath
                )

                cell.configure(objectType: type, name: name, isOpened: isOpened)

                let subject = PublishSubject<Void>()
                
                subject
                    .map { item.identity }
                    .bind(to: self.requestGuestAccess)
                    .disposed(by: cell.disposeBag)
                
                cell.bind(with: subject)

                return cell

            case let .doorPreviewPager(identity, items):
                let cell = collectionView.dequeueReusableCell(
                    withClass: AddressesListDoorPreviewPagerCell.self,
                    for: indexPath
                )

                cell.configure(
                    items: items,
                    selectedIdentity: self.selectedDoorPreviewIdentity(for: identity)
                )

                cell.openRequested
                    .do(onNext: { [weak self] identity in
                        self?.rememberDoorPreviewIdentity(identity)
                    })
                    .bind(to: self.requestGuestAccess)
                    .disposed(by: cell.disposeBag)

                cell.previewSelected
                    .do(onNext: { [weak self] identity in
                        self?.rememberDoorPreviewIdentity(identity)
                    })
                    .bind(to: self.previewSelected)
                    .disposed(by: cell.disposeBag)

                return cell

            case let .doorPreview(_, title, subtitle, previewSource, hasCamera, isOpened):
                let cell = collectionView.dequeueReusableCell(
                    withClass: AddressesListDoorPreviewCell.self,
                    for: indexPath
                )

                cell.configure(
                    title: title,
                    subtitle: subtitle,
                    previewSource: previewSource,
                    hasCamera: hasCamera,
                    isOpened: isOpened
                )

                let subject = PublishSubject<Void>()

                subject
                    .map { item.identity }
                    .bind(to: self.requestGuestAccess)
                    .disposed(by: cell.disposeBag)

                cell.bind(with: subject)

                return cell
                
            case let .cameras(_, numberOfCameras):
                let cell = collectionView.dequeueReusableCell(
                    withClass: AddressesListCameraCell.self,
                    for: indexPath
                )
                cell.configure(availableCameras: numberOfCameras)
                return cell
            
            case let .history(_, eventsCount):
                let cell = collectionView.dequeueReusableCell(
                    withClass: AddressesListHistoryCell.self,
                    for: indexPath
                )
                cell.configure(itemsCount: eventsCount)
                return cell

            case let .extensionItem(_, caption, iconURL, isHighlighted):
                let cell = collectionView.dequeueReusableCell(
                    withClass: AddressesListExtensionCell.self,
                    for: indexPath
                )
                cell.configure(
                    caption: caption,
                    icon: UIImage(base64URLString: iconURL),
                    isHighlighted: isHighlighted
                )
                return cell
                
            case let .unapprovedAddresses(_, address):
                let cell = collectionView.dequeueReusableCell(
                    withClass: UnapprovedObjectCell.self,
                    for: indexPath
                )
                cell.configure(address: address)
                cell.bind(with: qrCodeTapped)
                return cell
                
            case .emptyState: fatalError("Should be handled separately")
            case .offlineDoor(_, _): fatalError("Should be handled on the offline screen")
            }
        }()
        
        guard
            let itemsCountDict = try? itemsCountProxy.value(),
            let totalItemsInSection = itemsCountDict[indexPath.section]
        else {
            return customizableCell
        }
        
        let isFirstInSection = indexPath.row == 0
        let isLastInSection = indexPath.row == totalItemsInSection - 1
        
        customizableCell.addCustomBorder(
            isFirstInSection: isFirstInSection,
            isLastInSection: isLastInSection,
            customBorderWidth: 1,
            customBorderColor: UIColor.SmartYard.grayBorder,
            customlayerCornerRadius: 12
        )
        
        return customizableCell
    }

}

private extension AddressesListViewController {

    func configureAddButton() {
        if #available(iOS 15.0, *) {
            addButton.configuration = nil
        }
        addButton.imageForNormal = UIImage(named: "AddButtonIcon")
        addButton.imageForHighlighted = UIImage(named: "AddButtonIcon")?.darkened()
    }

    func configureStoriesCollectionView() {
        storiesFlowLayout.scrollDirection = .horizontal
        storiesFlowLayout.minimumLineSpacing = StoriesLayout.lineSpacing
        storiesFlowLayout.minimumInteritemSpacing = 0

        storiesCollectionView.backgroundColor = .clear
        storiesCollectionView.showsHorizontalScrollIndicator = false
        storiesCollectionView.showsVerticalScrollIndicator = false
        storiesCollectionView.decelerationRate = .fast
        storiesCollectionView.isHidden = true
        storiesCollectionView.register(cellWithClass: StoryItemCell.self)

        view.addSubview(storiesCollectionView) { make in
            make.top.equalTo(headerView.snp.bottom).offset(StoriesLayout.topOffset)
            make.leading.trailing.equalToSuperview()
            storiesHeightConstraint = make.height.equalTo(0).constraint
        }

        mainContainerTopConstraint = view.constraints
            .first { constraint in
                constraint.firstItem === mainContainerView
                    && constraint.firstAttribute == .top
                    && constraint.secondItem === headerView
                    && constraint.secondAttribute == .bottom
            }
        headerTopConstraint = view.constraints
            .first { $0.firstItem === headerView && $0.firstAttribute == .top }
        addButtonTrailingConstraint = view.constraints
            .first { $0.secondItem === addButton && $0.secondAttribute == .trailing }
        addButtonSizeConstraints = addButton.constraints.filter { [.width, .height].contains($0.firstAttribute) }
        defaultOffsets = (
            headerTopConstraint?.constant ?? 0,
            mainContainerTopConstraint?.constant ?? 0,
            addButtonTrailingConstraint?.constant ?? 0,
            addButtonSizeConstraints.first?.constant ?? 0
        )

        storiesCollectionView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
    }

    func configureStoriesDataSource() {
        storiesDataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, StoryItemCellModel>>(
            configureCell: { _, collectionView, indexPath, model in
                let cell = collectionView.dequeueReusableCell(withClass: StoryItemCell.self, for: indexPath)
                cell.configure(with: model)
                return cell
            }
        )
    }

    func updateStoriesVisibility(hasStories: Bool) {
        storiesCollectionView.isHidden = !hasStories
        storiesHeightConstraint?.update(offset: hasStories ? StoriesLayout.height : 0)
        headerTopConstraint?.constant = hasStories ? StoriesLayout.headerTopOffset : defaultOffsets.headerTop
        mainContainerTopConstraint?.constant = hasStories
            ? StoriesLayout.mainContainerTopOffset
            : defaultOffsets.mainTop
        addButtonTrailingConstraint?.constant = hasStories ? StoriesLayout.addButtonTrailingOffset : defaultOffsets.addTrailing
        addButtonSizeConstraints.forEach { $0.constant = hasStories ? StoriesLayout.addButtonSize : defaultOffsets.addSize }
        storiesCollectionView.collectionViewLayout.invalidateLayout()

        UIView.performWithoutAnimation {
            view.layoutIfNeeded()
        }
    }

}

private extension AddressesListViewController {
    func bindSelectedDoorPreviewIdentity(_ output: AddressesListViewModel.Output) {
        output.selectedDoorPreviewIdentity
            .drive(with: self) { owner, identity in
                owner.rememberDoorPreviewIdentity(identity)
                owner.selectVisibleDoorPreview(identity: identity)
            }
            .disposed(by: disposeBag)
    }

    func rememberDoorPreviewIdentity(_ identity: AddressesListDataItemIdentity) {
        guard case let .object(addressId, _, _, _) = identity else {
            return
        }

        selectedDoorPreviewIdentityByAddressId[addressId] = identity
    }

    func selectedDoorPreviewIdentity(
        for identity: AddressesListDataItemIdentity
    ) -> AddressesListDataItemIdentity? {
        guard case let .doorPreviewPager(addressId) = identity else {
            return nil
        }

        return selectedDoorPreviewIdentityByAddressId[addressId]
    }

    func selectVisibleDoorPreview(identity: AddressesListDataItemIdentity) {
        collectionView.visibleCells
            .compactMap { $0 as? AddressesListDoorPreviewPagerCell }
            .forEach { $0.select(identity: identity, animated: false) }
    }
}

extension AddressesListViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if collectionView == storiesCollectionView {
            return CGSize(width: StoriesLayout.itemWidth, height: collectionView.bounds.height)
        }

        guard let item = dataSource?[indexPath] else { return .zero }

        switch item {
        case .emptyState:
            return CGSize(
                width: collectionView.width - 32,
                height: collectionView.bounds.height - 36
            )

        case let .header(_, address, _):
            let height = AddressesHeaderCell
                .preferredHeight(
                    for: UIScreen.main.bounds.width - 32,
                    title: address
                )
                .totalHeight

            return CGSize(
                width: UIScreen.main.bounds.width - 32,
                height: height
            )

        case .doorPreview, .doorPreviewPager:
            return CGSize(
                width: collectionView.width - 32,
                height: 176
            )

        default:
            return CGSize(
                width: collectionView.width - 32,
                height: 72
            )
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        if collectionView == storiesCollectionView {
            return StoriesLayout.lineSpacing
        }

        return 0
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 0
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        if collectionView == storiesCollectionView {
            return UIEdgeInsets(
                top: 0,
                left: StoriesLayout.horizontalInset,
                bottom: 0,
                right: StoriesLayout.horizontalInset
            )
        }

        let topInset: CGFloat = {
            switch section {
            case 0: return 16
            default: return 10
            }
        }()
        
        let bottomInset: CGFloat = {
            switch section {
            case collectionView.numberOfSections - 1: return 20
            default: return 0
            }
        }()
        
        return UIEdgeInsets(top: topInset, left: 16, bottom: bottomInset, right: 16)
    }
    
}

extension AddressesListViewController: UICollectionViewDragDelegate {
    
    func collectionView(
        _ collectionView: UICollectionView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {
        guard
            indexPath.row == 0,
            let header = dataSource?[indexPath]
        else {
            return []
        }

        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return []
        }

        let renderer = UIGraphicsImageRenderer(bounds: cell.bounds)
        let image = renderer.image { cell.layer.render(in: $0.cgContext) }

        let snapshotView = UIImageView(image: image)
        snapshotView.frame = cell.frame
        snapshotView.layer.cornerRadius = 12
        snapshotView.clipsToBounds = true
        
        viewModel.collapseAllSections()
        collectionView.layoutIfNeeded()

        let provider = NSItemProvider(object: NSString())
        let dragItem = UIDragItem(itemProvider: provider)
        dragItem.localObject = header.identity
        dragItem.previewProvider = { UIDragPreview(view: snapshotView) }
        
        return [dragItem]
    }
    
}

extension AddressesListViewController: UICollectionViewDropDelegate {
    
    func collectionView(
        _ collectionView: UICollectionView,
        performDropWith coordinator: UICollectionViewDropCoordinator
    ) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }

        for wrapper in coordinator.items {
            guard
                let identity = wrapper.dragItem.localObject as? AddressesListDataItemIdentity,
                case .header = identity,
                let sourceIndexPath = wrapper.sourceIndexPath,
                sourceIndexPath.row == 0
            else { continue }

            viewModel.moveApprovedAddress(
                from: sourceIndexPath.section,
                to: destinationIndexPath.section
            )

            let target = IndexPath(item: 0, section: destinationIndexPath.section)
            coordinator.drop(wrapper.dragItem, toItemAt: target)
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UICollectionViewDropProposal {
        if session.localDragSession != nil {
            return UICollectionViewDropProposal(
                operation: .move,
                intent: .insertAtDestinationIndexPath
            )
        } else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
    }
    
}

extension AddressesListViewController {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        collectionView.reloadData()
    }
    
}
