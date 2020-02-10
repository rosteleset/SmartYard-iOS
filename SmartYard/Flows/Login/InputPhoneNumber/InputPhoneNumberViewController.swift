//
//  InputPhoneNumberViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 05.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class InputPhoneNumberViewController: BaseViewController {
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var phoneTextView: PhoneTextField!
    
    private var viewModel: InputPhoneNumberViewModel
    
    init(viewModel: InputPhoneNumberViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.hideKeyboardWhenTapped = true
        bind()
    }
    
    private func bind() {
        let phoneTextSubject = PublishSubject<String>()
        
        phoneTextView.rx.textControlProperty
            .map { $0 ?? "" }
            .bind(to: phoneTextSubject)
            .disposed(by: disposeBag)
        
        let input = InputPhoneNumberViewModel.Input(
            inputPhoneText: phoneTextSubject.asDriver(onErrorJustReturn: "")
        )
        
        _ = viewModel.transform(input: input)
    }
    
}
