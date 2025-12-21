//
//  HomeOfflineViewController.swift
//  SmartYard
//
//  Created by Александр Попов on 19.10.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa
import RxDataSources

final class HomeOfflineViewController: BaseViewController, UIScrollViewDelegate {
    @IBOutlet private weak var headerView: HeaderView!
    @IBOutlet private weak var mainContainerView: UIView!
    @IBOutlet private weak var skeletonContainer: UIView!
    @IBOutlet private weak var collectionView: UICollectionView!
    
    private let didAttemptToDismissRelay = PublishRelay<Void>()
    private let itemsCountProxy = BehaviorRelay<[Int: Int]>(value: [:])
    private var canDismiss = false

    private let viewModel: HomeOfflineViewModel
    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<AddressesListSectionModel>?

    init(viewModel: HomeOfflineViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if skeletonContainer.sk.isSkeletonActive {
            skeletonContainer.showSkeletonAsynchronously(with: UIColor.SmartYard.secondBackgroundColor)
        }
    }

    private func setupUI() {
        presentationController?.delegate = self
        configureView()
        configureCollectionView()
    }

    private func configureView() {
        headerView.setText(
            NSLocalizedString("My Addresses", comment: ""),
            subtitle: NSLocalizedString("offline.hint.swipe_to_exit", comment: ""),
        )

        mainContainerView.layerCornerRadius = 24
        mainContainerView.layer.maskedCorners = .topCorners
    }

    private func configureCollectionView() {
        [
            AddressesListEmptyStateCell.self,
            OfflineDoorCodeCell.self
        ].forEach {
            collectionView.register(nibWithCellClass: $0)
        }

        collectionView.register(cellWithClass: AddressesHeaderCell.self)

        let dataSource = RxCollectionViewSectionedAnimatedDataSource<AddressesListSectionModel>(
            configureCell: { [weak self] _, collectionView, indexPath, item in
                guard let self else {
                    let cell = collectionView.dequeueReusableCell(
                        withClass: AddressesHeaderCell.self,
                        for: indexPath
                    )
                    return cell
                }

                let cell = configureCell(
                    collectionView: collectionView,
                    indexPath: indexPath,
                    item: item
                )
                return cell
            }
        )

        collectionView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)

        self.dataSource = dataSource
    }

    private func bind() {
        guard let dataSource else { return }

        let itemSelectedIdentity = collectionView.rx
            .modelSelected(AddressesListDataItem.self)
            .map { $0.identity }

        let input = HomeOfflineViewModel.Input(
            viewDidLoad: Observable.just(()),
            itemSelected: itemSelectedIdentity,
            didAttemptToDismiss: didAttemptToDismissRelay.asObservable()
        )

        let output = viewModel.transform(input)

        output.itemsCountBySection
            .drive { [weak self] dict in
                self?.itemsCountProxy.accept(dict)
            }
            .disposed(by: disposeBag)

        output.sectionModels
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        output.shouldBlockInteraction
            .drive { [weak self] shouldBlockInteraction in
                self?.collectionView.isHidden = shouldBlockInteraction
                self?.skeletonContainer.isHidden = !shouldBlockInteraction

                shouldBlockInteraction ?
                self?.skeletonContainer.showSkeletonAsynchronously(with: UIColor.SmartYard.backgroundColor) :
                self?.skeletonContainer.hideSkeleton()
            }
            .disposed(by: disposeBag)

        output.allowDismiss
            .drive { [weak self] _ in
                self?.canDismiss = true
            }
            .disposed(by: disposeBag)

        // MARK: Скроллим таблицу при сворачивании / разворачивании секций для лучшего UX

        let updateKindSubject = BehaviorSubject<AddressesListSectionUpdateKind?>(value: nil)
        let updateKind = updateKindSubject.asDriver(onErrorJustReturn: nil)

        output.updateKind
            .drive { updateKindSubject.onNext($0) }
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
            cell.configure(with: .offline)
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

            case let .offlineDoor(_, viewModel):
                let cell = collectionView.dequeueReusableCell(
                    withClass: OfflineDoorCodeCell.self,
                    for: indexPath
                )
                cell.configure(with: viewModel)
                return cell

            case .emptyState: fatalError("Should be handled separately")
            default: fatalError("Unhandled item type: \(item)")
            }
        }()

        let itemsCountDict = itemsCountProxy.value
        guard let totalItemsInSection = itemsCountDict[indexPath.section] else {
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

extension HomeOfflineViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(
        _ presentationController: UIPresentationController
    ) -> Bool {
        return canDismiss
    }

    func presentationControllerDidAttemptToDismiss(
        _ presentationController: UIPresentationController
    ) {
        didAttemptToDismissRelay.accept(())
    }
}

extension HomeOfflineViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
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

extension HomeOfflineViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        collectionView.reloadData()
    }
}
