//
//  AddressDeletionViewController.swift
//  SmartYard
//
//  Created by admin on 14/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import TouchAreaInsets

final class AddressDeletionViewController: BaseViewController {
    
    @IBOutlet private weak var wantToBreakTheContractContainer: UIView!
    @IBOutlet private weak var wantToBreakTheContractCheckbox: SmartYardCheckBoxView!
    
    @IBOutlet private weak var otherReasonContainer: UIView!
    @IBOutlet private weak var otherReasonCheckbox: SmartYardCheckBoxView!
    
    @IBOutlet private weak var reasonTextContainer: UIView!
    @IBOutlet private weak var reasonTextField: UITextField!
    
    @IBOutlet private var mainContainerBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var deleteButton: BlueButton!
    @IBOutlet private weak var cancelButton: UIButton!
    
    private let viewModel: AddressDeletionViewModel
    
    init(viewModel: AddressDeletionViewModel) {
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
    
    private func bind() {
        let wantToBreakTheContractGesture = UITapGestureRecognizer()
        wantToBreakTheContractContainer.addGestureRecognizer(wantToBreakTheContractGesture)
        
        let otherReasonGesture = UITapGestureRecognizer()
        otherReasonContainer.addGestureRecognizer(otherReasonGesture)
        
        let deletionReason = Observable<AddressDeletionReason>
            .merge(
                wantToBreakTheContractGesture.rx.event.map { _ in .wantToBreakTheContract },
                otherReasonGesture.rx.event.map { _ in .other },
                .just(.wantToBreakTheContract)
            )
            .asDriverOnErrorJustComplete()
            .distinctUntilChanged()
            .do(
                onNext: { [weak self] reason in
                    self?.selectReason(reason)
                }
            )
        
        let cancelTrigger = cancelButton.rx.tap
            .asDriver()
            .do(
                onNext: { [weak self] in
                    self?.view.endEditing(true)
                }
            )
        
        let deleteTrigger = deleteButton.rx.tap
            .asDriver()
            .do(
                onNext: { [weak self] in
                    self?.view.endEditing(true)
                }
            )
        
        let input = AddressDeletionViewModel.Input(
            cancelTrigger: cancelTrigger,
            deleteTrigger: deleteTrigger,
            deletionReason: deletionReason,
            customDescription: reasonTextField.rx.text.asDriver().distinctUntilChanged()
        )
        
        _ = viewModel.transform(input)
    }
    
    private func configureView() {
        let attrString = NSAttributedString(
            string: NSLocalizedString("Specify a reason", comment: ""),
            attributes: [
                .font: UIFont.SourceSansPro.regular(size: 14),
                .foregroundColor: UIColor.SmartYard.gray.withAlphaComponent(0.4) as Any
            ]
        )
        
        reasonTextField.attributedPlaceholder = attrString
        reasonTextField.delegate = self
        
        let gesture = UITapGestureRecognizer()
        reasonTextContainer.addGestureRecognizer(gesture)
        reasonTextContainer.touchAreaInsets = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        
        gesture.rx.event
            .subscribe(
                onNext: { [weak self] _ in
                    self?.reasonTextField.becomeFirstResponder()
                }
            )
            .disposed(by: disposeBag)
        
        cancelButton.touchAreaInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
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
    
    private func selectReason(_ reason: AddressDeletionReason) {
        [wantToBreakTheContractCheckbox, otherReasonCheckbox].forEach {
            $0?.setState(state: .uncheckedInactive)
        }
        
        reasonTextField.text = nil
        reasonTextField.sendActions(for: .valueChanged)
        
        switch reason {
        case .wantToBreakTheContract:
            wantToBreakTheContractCheckbox.setState(state: .checkedActive)
            
            reasonTextField.resignFirstResponder()
            reasonTextContainer.isHidden = true
            
        case .other:
            otherReasonCheckbox.setState(state: .checkedActive)
            
            reasonTextField.becomeFirstResponder()
            reasonTextContainer.isHidden = false
        }
    }
    
}

extension AddressDeletionViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
