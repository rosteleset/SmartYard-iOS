//
//  SelectCameraContainerViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 13.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import AVKit
import Parchment

final class SelectCameraContainerViewController: BaseViewController {

    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var headerView: HeaderView!
    @IBOutlet private weak var pagingContainer: TopRoundedView!

    private var pagingController: PagingViewController?

    private let onlinePage: OnlinePageViewController
    private let archivePage: ArchivePageViewController
    private let viewModel: SelectCameraContainerViewModel

    // UI events
    private let selectDateTrigger = PublishSubject<Date>()
    private let selectCameraIdTrigger = PublishSubject<CameraID>()

    private var isArchivePageEnabled = false

    // Stored "truth"
    private let selectedCameraIdRelay = BehaviorRelay<CameraID?>(value: nil)
    private let camerasByIdRelay = BehaviorRelay<[CameraID: CameraObject]>(value: [:])

    init(
        onlinePage: OnlinePageViewController,
        archivePage: ArchivePageViewController,
        viewModel: SelectCameraContainerViewModel
    ) {
        self.onlinePage = onlinePage
        self.archivePage = archivePage
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configurePaging()
        bind()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pagingController?.view.frame = pagingContainer.bounds
        pagingController?.menuItemSize = .sizeToFit(minWidth: 100, height: 70)
    }

    private func configurePaging() {
        let pagingController = PagingViewController(viewControllers: [onlinePage, archivePage])
        self.pagingController = pagingController

        addChild(pagingController)
        pagingContainer.addSubview(pagingController.view)
        pagingController.didMove(toParent: self)

        pagingController.font = UIFont.SourceSansPro.regular(size: 18)
        pagingController.selectedFont = UIFont.SourceSansPro.semibold(size: 18)

        pagingController.menuBackgroundColor = UIColor.SmartYard.secondBackgroundColor
        pagingController.textColor = UIColor.SmartYard.gray
        pagingController.selectedTextColor = UIColor.SmartYard.semiBlack

        pagingController.menuItemSize = .sizeToFit(minWidth: 100, height: 70)
        pagingController.collectionView.isScrollEnabled = false
        pagingController.contentInteraction = .none
        pagingController.delegate = self
        pagingController.register(SelectCameraPagingTitleCell.self, for: PagingIndexItem.self)

        onlinePage.delegate = self
        archivePage.delegate = self
    }

    private func bind() {

        selectCameraIdTrigger
            .bind(to: selectedCameraIdRelay)
            .disposed(by: disposeBag)

        let input = SelectCameraContainerViewModel.Input(
            selectedCameraIdTrigger: selectedCameraIdRelay
                .compactMap { $0 }
                .asDriver(onErrorDriveWith: .empty()),
            selectedDateTrigger: selectDateTrigger.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
        )

        let output = viewModel.transform(input)

        output.cameraConfiguration
            .drive(with: self) { owner, config in
                let dict: [CameraID: CameraObject] = Dictionary(
                    uniqueKeysWithValues: config.cameras.map { ($0.id, $0) }
                )

                owner.camerasByIdRelay.accept(dict)

                owner.selectedCameraIdRelay.accept(config.preselectedCameraId)

                owner.onlinePage.applyConfiguration(
                    cameras: config.cameras,
                    preselectedCameraId: config.preselectedCameraId
                )
            }
            .disposed(by: disposeBag)

        Driver.combineLatest(
            output.address,
            selectedCameraIdRelay.asDriver().compactMap { $0 },
            camerasByIdRelay.asDriver()
        )
        .drive { [weak self] address, cameraId, camerasById in
            guard let camera = camerasById[cameraId] else { return }
            self?.headerView.setText(camera.name, subtitle: address)
        }
        .disposed(by: disposeBag)

        output.rangesForCurrentCamera
            .drive(with: self) { owner, ranges in
                owner.archivePage.setAvailableRanges(ranges)
            }
            .disposed(by: disposeBag)

        output.isArchiveAvailable
            .drive(with: self) { owner, isAvailable in
                owner.setArchivePageEnabled(isAvailable)
            }
            .disposed(by: disposeBag)

        output.areRangesBeingLoaded
            .drive(with: self) { owner, isLoading in
                owner.archivePage.updateLoader(isEnabled: isLoading, detailText: nil)
            }
            .disposed(by: disposeBag)
    }
}

// MARK: - Archive Availability
private extension SelectCameraContainerViewController {
    func setArchivePageEnabled(_ isEnabled: Bool) {
        isArchivePageEnabled = isEnabled
        SelectCameraPagingTitleCell.isArchiveEnabled = isEnabled
        pagingController?.collectionView.reloadData()
    }
}

// MARK: - PagingViewControllerDelegate
extension SelectCameraContainerViewController: PagingViewControllerDelegate {
    func pagingViewController(
        _ pagingViewController: PagingViewController,
        didSelectItem pagingItem: PagingItem
    ) {
        guard let item = pagingItem as? PagingIndexItem,
              item.index == 1,
              !isArchivePageEnabled else { return }

        pagingViewController.select(index: 0, animated: true)
    }

    func pagingViewController(
        _ pagingViewController: PagingViewController,
        didScrollToItem pagingItem: PagingItem,
        startingViewController: UIViewController?,
        destinationViewController: UIViewController,
        transitionSuccessful: Bool
    ) {
        guard transitionSuccessful, destinationViewController === archivePage, !isArchivePageEnabled else { return }
        pagingViewController.select(index: 0, animated: true)
    }
}

private final class SelectCameraPagingTitleCell: PagingTitleCell {
    static var isArchiveEnabled = false

    private var isArchiveItem = false

    override func setPagingItem(_ pagingItem: PagingItem, selected: Bool, options: PagingOptions) {
        isArchiveItem = (pagingItem as? PagingIndexItem)?.index == 1
        super.setPagingItem(pagingItem, selected: selected, options: options)
        updateArchiveAvailability()
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        updateArchiveAvailability()
    }

    private func updateArchiveAvailability() {
        guard isArchiveItem, !Self.isArchiveEnabled else {
            isUserInteractionEnabled = true
            titleLabel.alpha = 1
            return
        }

        isUserInteractionEnabled = false
        titleLabel.textColor = UIColor.SmartYard.gray.withAlphaComponent(0.5)
        titleLabel.alpha = 1
    }
}

// MARK: - OnlinePageViewControllerDelegate
extension SelectCameraContainerViewController: OnlinePageViewControllerDelegate {
    func onlinePageViewController(_ vc: OnlinePageViewController, didSelectCameraId id: CameraID) {
        selectCameraIdTrigger.onNext(id)
    }
}

// MARK: - ArchivePageViewControllerDelegate
extension SelectCameraContainerViewController: ArchivePageViewControllerDelegate {
    func archivePageViewController(_ vc: ArchivePageViewController, didSelectDate date: Date) {
        selectDateTrigger.onNext(date)
    }
}
