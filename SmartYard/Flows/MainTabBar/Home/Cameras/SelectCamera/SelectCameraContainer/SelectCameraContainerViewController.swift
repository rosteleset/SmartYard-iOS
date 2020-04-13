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
    
    init(viewModel: SelectCameraContainerViewModel) {
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
        bind()
    }
    
    private func configureUI() {
        segmentControlView.segmentItems = ["Онлайн", "Архив"]
    }
    
    private func bind() {
        let selectedSegmentIndex = PublishSubject<Int>()
        
        segmentControlView.rx.selectedIndex
            .bind(to: selectedSegmentIndex)
            .disposed(by: disposeBag)
        
        selectedSegmentIndex.asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] index in
                    guard index == 0 else {
                        self?.onlineView.isHidden = false
                        self?.archiveView.isHidden = true
                        
                        return
                    }
                    
                    self?.onlineView.isHidden = true
                    self?.archiveView.isHidden = false
                }
            )
            .disposed(by: disposeBag)
        
        let input = SelectCameraContainerViewModel.Input(
            confirmByCourierTapped: courierView.rx.requestButtonTapped.asDriverOnErrorJustComplete(),
            confirmInOfficeTrigger: officeView.rx.doSoButtonTapped.asDriverOnErrorJustComplete(),
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
        
        output.offices
            .drive(
                onNext: { [weak self] offices in
                    self?.officeView.setOffices(offices: offices)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
