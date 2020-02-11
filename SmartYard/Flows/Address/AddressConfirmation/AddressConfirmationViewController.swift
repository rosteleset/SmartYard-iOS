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
        
        segmentControl.rx.selectedIndexControlProperty
            .bind(to: selectedSegmentIndex)
            .disposed(by: disposeBag)
        
        selectedSegmentIndex.asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] index in
                    let isFirstSelected = index == 0
                    self?.officeView.isHidden = isFirstSelected
                    self?.courierView.isHidden = !isFirstSelected
                }
            )
            .disposed(by: disposeBag)
    }
    
}
