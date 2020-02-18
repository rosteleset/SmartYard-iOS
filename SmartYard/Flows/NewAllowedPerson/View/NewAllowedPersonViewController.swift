//
//  NewAllowedPersonViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 17.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxKeyboard
import RxSwift
import RxCocoa
import ContactsUI
import Contacts

class NewAllowedPersonViewController: BaseViewController {
    
    @IBOutlet weak var textField: LimitedTextField!
    @IBOutlet weak var selectFromContactButton: UIButton!
    @IBOutlet weak var contactImageView: RoundedImageView!
    @IBOutlet weak var contactNameLabel: UILabel!
    
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var addAccessButton: BlueButton!
    @IBOutlet private weak var mainContainerBottomConstraint: NSLayoutConstraint!
    
    private let contactPicker = CNContactPickerViewController()
    
    let newContactTrigger = PublishSubject<AllowedPerson?>()
    
    private let closeTrigger = PublishSubject<Void>()
    
    private let viewModel: NewAllowedPersonViewModel
    
    init(viewModel: NewAllowedPersonViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureRxKeyboard()
        bind()
    }
    
    private func configureView() {
        view.hideKeyboardWhenTapped = true

        let dismissTap = UITapGestureRecognizer()
        
        backgroundView.addGestureRecognizer(dismissTap)
        
        dismissTap.rx
            .event
            .subscribe(
                onNext: { [weak self] _ in
                    self?.closeTrigger.onNext(())
                }
            )
            .disposed(by: disposeBag)
        
        textField.delegate = self

        let prefixLabel = UILabel()
        prefixLabel.text = "+7"
        prefixLabel.font = UIFont.SourceSansPro.semibold(size: 18)
        prefixLabel.sizeToFit()

        textField.leftView = prefixLabel
        textField.leftViewMode = .whileEditing
    }
    
    private func bind() {
        let phoneTextDriver = textField.rx.text
            .orEmpty
            .observeOn(MainScheduler.asyncInstance)
            .asDriver(onErrorJustReturn: "")
            
        phoneTextDriver
            .drive(
                onNext: { [weak self] text in
                    guard let self = self else {
                        return
                    }
                    
                    self.addAccessButton.isEnabled = text.count == Constants.phoneLengthWithoutPrefix
                }
            )
            .disposed(by: disposeBag)
        
        let phoneTextCompletedDriver = phoneTextDriver
            .filter { $0.count == Constants.phoneLengthWithoutPrefix }
        
        selectFromContactButton.rx
            .tap
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    self.contactPicker.delegate = self
                    self.present(self.contactPicker, animated: true, completion: nil)
                    self.textField.isHidden = true
                    self.contactNameLabel.isHidden = false
                }
            )
            .disposed(by: disposeBag)
        
        let input = NewAllowedPersonViewModel.Input(
            closeTrigger: closeTrigger.asDriver(onErrorJustReturn: ()),
            selectFromContactTrigger: selectFromContactButton.rx.tap.asDriverOnErrorJustComplete(),
            addAccessTrigger: addAccessButton.rx.tap.asDriverOnErrorJustComplete(),
            inputPhoneTextTrigger: phoneTextCompletedDriver.asDriver(onErrorJustReturn: "")
        )
        
        let output = viewModel.transform(input)
    }
    
    private func configureRxKeyboard() {
        RxKeyboard.instance.visibleHeight
            .debounce(.milliseconds(100))
            .drive(
                onNext: { [weak self] keyboardVisibleHeight in
                    self?.mainContainerBottomConstraint.constant = keyboardVisibleHeight == 0 ?
                        0 :
                        keyboardVisibleHeight + 16
                    
                    UIView.animate(withDuration: 0.25) {
                        self?.view.layoutIfNeeded()
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
}

extension NewAllowedPersonViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
