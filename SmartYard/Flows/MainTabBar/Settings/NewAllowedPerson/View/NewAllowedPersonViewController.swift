//
//  NewAllowedPersonViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 17.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length

import UIKit
import RxSwift
import RxCocoa
import ContactsUI
import Contacts
import SHSPhoneComponent

class NewAllowedPersonViewController: BaseViewController {
    
    @IBOutlet weak var textField: SHSPhoneTextField!
    @IBOutlet weak var selectFromContactButton: UIButton!
    @IBOutlet weak var contactImageView: RoundedImageView!
    @IBOutlet weak var contactNameLabel: UILabel!
    @IBOutlet weak var addAccessButton: BlueButton!
    
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var mainContainerBottomConstraint: NSLayoutConstraint!
    
    private let contactPicker = CNContactPickerViewController()
    
    private let rawPhoneAddedTrigger = PublishSubject<String>()
    private let cnContactAddedTrigger = PublishSubject<(CNContact, Int)>()
    
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
                    guard let self = self else {
                        return
                    }
                    self.mainContainerBottomConstraint.constant = (keyboardVisibleHeight == 0) || (self.view.frame.height == keyboardVisibleHeight) ?
                        0 :
                        keyboardVisibleHeight + 16
                    
                    UIView.animate(withDuration: 0.25) {
                        self.view.layoutIfNeeded()
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
        
        let mobileNumbers = contact.phoneNumbers.enumerated()
            .filter { _, phoneNumber in
                // если это не сотовый номер, то пропускаем и не показываем для выбора
                guard let rawNumber = phoneNumber.value.stringValue.rawPhoneNumberFromFullNumber,
                      rawNumber[0] == "9" else {
                    return false
                }
                return true
            }
        
        switch mobileNumbers.count {
        case 0:
            return
        case 1:
            self.cnContactAddedTrigger.onNext((contact, 0))
        default:
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            mobileNumbers.forEach { phoneIndex, phoneNumber in
                
                let action = UIAlertAction(
                    title: phoneNumber.value.stringValue,
                    style: .default,
                    handler: { [weak self] _ in
                        guard let self = self else {
                            return
                        }
                        
                        self.cnContactAddedTrigger.onNext((contact, phoneIndex))
                    }
                )
                alert.addAction(action)
            }
        
            let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
            alert.addAction(cancelAction)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
                self.viewController.present(alert, animated: true, completion: nil)
            })
        }
    }

}
// swiftlint:enable function_body_length
