//
//  SelectCameraContainerViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 13.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import JGProgressHUD

class SelectCameraContainerViewController: BaseViewController, LoaderPresentable {

    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var cameraNameLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var segmentControlView: SmartYardSegmentedControl!
    @IBOutlet private weak var onlineView: OnlineView!
    @IBOutlet private weak var archiveView: ArchiveView!
    
    var loader: JGProgressHUD?
    
    private let viewModel: SelectCameraContainerViewModel
    
    let selectDataTrigger = PublishSubject<Date?>()
    let selectCameraTrigger = PublishSubject<Int>()
    
    init(viewModel: SelectCameraContainerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        archiveView.parrentViewWillTransition(to: size, with: coordinator)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        archiveView.setupCalendar()
    }
    
    private func configureUI() {
        segmentControlView.segmentItems = ["Онлайн", "Архив"]
        archiveView.isHidden = true
        onlineView.isHidden = false
    }
    
    private func bind() {
        segmentControlView.rx
            .selectedIndex
            .asDriver()
            .drive(
                onNext: { [weak self] index in
                    guard index == 0 else {
                        self?.archiveView.isHidden = false
                        self?.onlineView.isHidden = true
                        
                        return
                    }
                    
                    self?.archiveView.isHidden = true
                    self?.onlineView.isHidden = false
                }
            )
            .disposed(by: disposeBag)
        
        let input = SelectCameraContainerViewModel.Input(
            selectedCameraTrigger: selectCameraTrigger.asDriverOnErrorJustComplete(),
            selectedDateTrigger: selectDataTrigger.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
        
        output.address
            .drive(addressLabel.rx.text)
            .disposed(by: disposeBag)

        onlineView.bind(with: output.cameras)
    }
    
}
