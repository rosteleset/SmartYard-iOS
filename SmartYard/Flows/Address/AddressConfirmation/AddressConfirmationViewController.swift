//
//  AddressConfirmationViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 11.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import JGProgressHUD

class AddressConfirmationViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var segmentControl: SmartYardSegmentedControl!
    
    @IBOutlet private weak var officeView: ServiceFromOfficeView!
    @IBOutlet private weak var courierView: ServiceFromCourierView!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    
    var loader: JGProgressHUD?
    
    private let viewModel: AddressConfirmationViewModel
    
    init(viewModel: AddressConfirmationViewModel) {
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
        segmentControl.segmentItems = ["Через курьера", "Визит в офис"]
    }
    
    private func bind() {
        segmentControl.rx
            .selectedIndex
            .asDriver()
            .drive(
                onNext: { [weak self] index in
                    guard index == 0 else {
                        self?.officeView.isHidden = false
                        self?.courierView.isHidden = true
                        
                        return
                    }
                    
                    self?.officeView.isHidden = true
                    self?.courierView.isHidden = false
                }
            )
            .disposed(by: disposeBag)
        
        let input = AddressConfirmationViewModel.Input(
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
