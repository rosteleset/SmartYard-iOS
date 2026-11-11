//
//  AddressesViewController.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import JGProgressHUD
import SkeletonView
import SnapKit
import SwifterSwift

final class AddressesListViewController: BaseViewController, LoaderPresentable {

    enum StoriesLayout {
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
    
    @IBOutlet private weak var headerView: UILabel!
    @IBOutlet private weak var mainContainerView: UIView!
    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private(set) weak var collectionView: UICollectionView!
    @IBOutlet private weak var skeletonContainer: UIView!
    
    private let storiesFlowLayout = UICollectionViewFlowLayout()
    lazy var storiesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: storiesFlowLayout)
    private var storiesHeightConstraint: Constraint?
    private weak var mainContainerTopConstraint: NSLayoutConstraint?
    private weak var headerTopConstraint: NSLayoutConstraint?
    private weak var addButtonTrailingConstraint: NSLayoutConstraint?
    private var addButtonSizeConstraints: [NSLayoutConstraint] = []
    private var defaultOffsets = (headerTop: CGFloat(0), mainTop: CGFloat(0), addTrailing: CGFloat(0), addSize: CGFloat(0))

    var dataSource: RxCollectionViewSectionedAnimatedDataSource<AddressesListSectionModel>?
    private var storiesDataSource: RxCollectionViewSectionedReloadDataSource<SectionModel<String, StoryItemCellModel>>?
    var refreshControl = UIRefreshControl()
    
    // MARK: Это костыль для того, чтобы понять, сколько на самом деле ячеек внутри секции
    // В методе configureCell у RxDataSource мы должны сконфигурировать ячейку
    // Но проблема в том, что RxDataSource выполняет операции обновления и добавления ячеек отдельно
    // Сначала выполняется обновление уже существующих ячеек, а потом добавляются новые
    // Поэтому на момент обновления ячеек мы не можем получить актуальное количество секций через dataSource[section]
    // Так что приходится проксировать количество ячеек в секциях в отдельный субъект и брать данные отсюда
    
    let itemsCountProxy = BehaviorSubject<[Int: Int]>(value: [:])
    
    let viewModel: AddressesListViewModel

    let requestGuestAccess = PublishSubject<AddressesListDataItemIdentity>()
    let previewSelected = PublishSubject<AddressesListDataItemIdentity>()
    let qrCodeTapped = PublishSubject<Void>()
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
    func bind() {
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
                let neededSectionOffset = sectionModels.firstIndex { model in
                    model.items.contains { $0.identity == updateKind.associatedIdentity }
                }
                
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
                    
                    if shouldBlockInteraction {
                        self?.skeletonContainer.showSkeletonAsynchronously(with: UIColor.SmartYard.backgroundColor)
                    } else {
                        self?.skeletonContainer.hideSkeleton()
                    }
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

}

private extension AddressesListViewController {

    func configureAddButton() {
        addButton.configuration = nil
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

extension AddressesListViewController {
    private func bindSelectedDoorPreviewIdentity(_ output: AddressesListViewModel.Output) {
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

    private func selectVisibleDoorPreview(identity: AddressesListDataItemIdentity) {
        collectionView.visibleCells
            .compactMap { $0 as? AddressesListDoorPreviewPagerCell }
            .forEach { $0.select(identity: identity, animated: false) }
    }
}
