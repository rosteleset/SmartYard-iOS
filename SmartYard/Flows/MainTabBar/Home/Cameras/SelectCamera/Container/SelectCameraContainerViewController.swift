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

        output.areRangesBeingLoaded
            .drive(with: self) { owner, isLoading in
                owner.archivePage.updateLoader(isEnabled: isLoading, detailText: nil)
            }
            .disposed(by: disposeBag)
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
