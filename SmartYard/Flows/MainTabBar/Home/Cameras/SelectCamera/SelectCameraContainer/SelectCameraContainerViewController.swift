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

class SelectCameraContainerViewController: BaseViewController {

    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var cameraNameLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var pagingContainer: TopRoundedView!
    
    private var pagingController: PagingViewController?
    
    private let onlinePage: OnlinePageViewController
    private let archivePage: ArchivePageViewController
    private let viewModel: SelectCameraContainerViewModel
    
    let selectDateTrigger = PublishSubject<Date>()
    let selectCameraTrigger = PublishSubject<CameraObject>()
    
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
        
        pagingController.textColor = UIColor.SmartYard.gray
        pagingController.selectedTextColor = UIColor.SmartYard.semiBlack
        
        pagingController.menuItemSize = .sizeToFit(minWidth: 100, height: 70)
        pagingController.indicatorColor = UIColor.SmartYard.blue
        
        pagingController.collectionView.isScrollEnabled = false
        pagingController.contentInteraction = .none
        
        onlinePage.delegate = self
        archivePage.delegate = self
    }
    
    private func bind() {
        let input = SelectCameraContainerViewModel.Input(
            selectedCameraTrigger: selectCameraTrigger.asDriverOnErrorJustComplete(),
            selectedDateTrigger: selectDateTrigger.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.address
            .drive(
                onNext: { [weak self] in
                    self?.addressLabel.text = $0
                }
            )
            .disposed(by: disposeBag)
        
        output.cameraConfiguration
            .drive(
                onNext: { [weak self] config in
                    self?.onlinePage.setCameras(config.cameras, selectedCamera: config.preselectedCamera)
                }
            )
            .disposed(by: disposeBag)
        
        output.rangesForCurrentCamera
            .drive(
                onNext: { [weak self] ranges in
                    self?.archivePage.setAvailableRanges(ranges)
                }
            )
            .disposed(by: disposeBag)
        
        output.areRangesBeingLoaded
            .drive(
                onNext: { [weak self] isLoading in
                    self?.archivePage.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
    }
    
}

extension SelectCameraContainerViewController: OnlinePageViewControllerDelegate {
    
    func onlinePageViewController(_ vc: OnlinePageViewController, didSelectCamera camera: CameraObject) {
        selectCameraTrigger.onNext(camera)
        
        cameraNameLabel.text = camera.name
    }
    
}

extension SelectCameraContainerViewController: ArchivePageViewControllerDelegate {
    
    func archivePageViewController(_ vc: ArchivePageViewController, didSelectDate date: Date) {
        selectDateTrigger.onNext(date)
    }
    
}
