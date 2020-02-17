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
import JGProgressHUD

class InputPhoneNumberViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var phoneTextView: PhoneTextField!
    
    private var viewModel: InputPhoneNumberViewModel
    
    var loader: JGProgressHUD?
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        phoneTextView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.endEditing(true)
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
        
        let output = viewModel.transform(input: input)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
