//
//  AddressConfirmationViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 11.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class AddressConfirmationViewController: BaseViewController {
    
    @IBOutlet private weak var segmentControl: SmartYardSegmentedControl!
    
    @IBOutlet private weak var officeView: ServiceFromOfficeView!
    @IBOutlet private weak var courierView: ServiceFromCourierView!
    
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
        let selectedSegmentIndex = PublishSubject<Int>()
        
        segmentControl.rx.selectedIndex
            .bind(to: selectedSegmentIndex)
            .disposed(by: disposeBag)
        
        selectedSegmentIndex.asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] index in
                    guard index == 0 else {
                        self?.officeView.isHidden = false
                        self?.courierView.isHidden = true
                        
                        self?.officeView.setPreview()
                        return
                    }
                    
                    self?.officeView.isHidden = true
                    self?.courierView.isHidden = false
                }
            )
            .disposed(by: disposeBag)
    }
    
}
