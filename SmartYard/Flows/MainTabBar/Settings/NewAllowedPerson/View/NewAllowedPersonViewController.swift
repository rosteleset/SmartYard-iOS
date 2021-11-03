//
//  NewAllowedPersonViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 17.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ContactsUI
import Contacts
import SHSPhoneComponent

class NewAllowedPersonViewController: BaseViewController {
    
    // swiftlint:disable all
    @IBOutlet weak var textField: SHSPhoneTextField!
    @IBOutlet weak var selectFromContactButton: UIButton!
    @IBOutlet weak var contactImageView: RoundedImageView!
    @IBOutlet weak var contactNameLabel: UILabel!
    @IBOutlet weak var addAccessButton: BlueButton!
    // swiftlint:enable all
    
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var mainContainerBottomConstraint: NSLayoutConstraint!
    
    private let contactPicker = CNContactPickerViewController()
    
    private let rawPhoneAddedTrigger = PublishSubject<String>()
    private let cnContactAddedTrigger = PublishSubject<CNContact>()
    
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
        
        textField.formatter.setDefaultOutputPattern(" (###) ###-##-##")
        
        textField.placeholder = "+7 (000) 000-00-00"
    }
    
    private func setPhoneNumberPrefix(prefix: String) {
        textField.formatter.prefix = prefix
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
        
        let dismissTap = UITapGestureRecognizer()
        backgroundView.addGestureRecognizer(dismissTap)
        
        let input = NewAllowedPersonViewModel.Input(
            closeTrigger: dismissTap.rx.event.mapToVoid().asDriver(onErrorJustReturn: ()),
            rawPhoneAddedTrigger: textField.rx.text.orEmpty.asDriver(onErrorJustReturn: ""),
            cnContactAddedTrigger: cnContactAddedTrigger.asDriverOnErrorJustComplete(),
            addAccessTrigger: addAccessButton.rx.tap.asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.isAbleToProceed
            .drive(addAccessButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        output.personWasSuccessfullyImported
            .drive(
                onNext: { [weak self] importedPerson in
                    self?.contactNameLabel.text = importedPerson.displayedName
                    self?.contactNameLabel.isHidden = false
                    
                    self?.contactImageView.image = importedPerson.logoImage ?? UIImage(named: "DefaultUserIcon")
                    
                    self?.textField.isHidden = true
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureRxKeyboard() {
        RxKeyboard.instance.visibleHeight
            .debounce(.milliseconds(50))
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard textField.text.isNilOrEmpty else {
            return
        }
        
        setPhoneNumberPrefix(prefix: "+7")
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard textField.text.isNilOrEmpty || textField.text?.trimmed == "+7" else {
            return
        }
        
        setPhoneNumberPrefix(prefix: "")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

extension NewAllowedPersonViewController: CNContactPickerDelegate {
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        cnContactAddedTrigger.onNext(contact)
    }

}
