//
//  NewAllowedPersonViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 17.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ContactsUI
import Contacts

class NewAllowedPersonViewController: BaseViewController {
    
    // swiftlint:disable all
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var selectFromContactButton: UIButton!
    @IBOutlet weak var contactImageView: RoundedImageView!
    @IBOutlet weak var contactNameLabel: UILabel!
    @IBOutlet weak var addAccessButton: BlueButton!
    // swiftlint:enable all
    
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var mainContainerBottomConstraint: NSLayoutConstraint!
    
    private let contactPicker = CNContactPickerViewController()
    
    var newContactTrigger = BehaviorSubject<AllowedPerson?>(value: nil)
    
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
        contactNameLabel.isHidden = true
        
        textField.isHidden = false
        textField.delegate = self

        let prefixLabel = UILabel()
        prefixLabel.text = "+7"
        prefixLabel.font = UIFont.SourceSansPro.semibold(size: 18)
        prefixLabel.sizeToFit()

        textField.leftView = prefixLabel
        textField.leftViewMode = .whileEditing
    }
    
    // swiftlint:disable:next function_body_length
    private func bind() {
        textField.rx
            .controlEvent(.editingChanged)
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    let containOnlyDigital = CharacterSet.decimalDigits.isSuperset(
                        of: CharacterSet(
                            charactersIn: self.textField.text ?? ""
                        )
                    )
                    
                    guard containOnlyDigital else {
                        self.textField.text = ""
                        return
                    }
                    
                    guard let editText = self.textField.text else {
                        return
                    }
                    
                    self.textField.text = String(editText.prefix(Constants.phoneLengthWithoutPrefix))
                }
            )
            .disposed(by: disposeBag)
        
        let phoneText = textField.rx.text
            .orEmpty
            .asDriver(onErrorJustReturn: "")
        
        phoneText
            .map { $0.count == Constants.phoneLengthWithoutPrefix }
            .drive(addAccessButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        phoneText
            .filter { $0.count == Constants.phoneLengthWithoutPrefix }
            .map { phoneText in
                var phoneFormatString = "+7" + phoneText
                phoneFormatString = phoneFormatString.formatAsPhoneNumber()
                
                return AllowedPerson(displayedName: nil, phoneNumber: phoneFormatString, logoImage: nil)
            }
            .drive(
                onNext: { [weak self] newAllowedPerson in
                    self?.newContactTrigger.onNext(newAllowedPerson)
                }
            )
            .disposed(by: disposeBag)
        
        selectFromContactButton.rx
            .tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    self.contactPicker.delegate = self
                    self.present(self.contactPicker, animated: true, completion: nil)
                }
            )
            .disposed(by: disposeBag)
        
        let addAccessTrigger = addAccessButton.rx.tap
            .asDriverOnErrorJustComplete()
            .withLatestFrom(newContactTrigger.asDriver(onErrorJustReturn: nil))
            .asDriver()
        
        let dismissTap = UITapGestureRecognizer()
        backgroundView.addGestureRecognizer(dismissTap)
        
        let input = NewAllowedPersonViewModel.Input(
            closeTrigger: dismissTap.rx.event.mapToVoid().asDriver(onErrorJustReturn: ()),
            addAccessTrigger: addAccessTrigger.asDriver()
        )
        
        _ = viewModel.transform(input)
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
