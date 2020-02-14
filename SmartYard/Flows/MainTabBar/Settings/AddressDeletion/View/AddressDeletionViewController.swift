//
//  AddressDeletionViewController.swift
//  SmartYard
//
//  Created by admin on 14/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import TouchAreaInsets

class AddressDeletionViewController: BaseViewController {
    
    @IBOutlet private weak var dontWantToManageFromAppContainer: UIView!
    @IBOutlet private weak var dontWantToManageFromAppCheckbox: SmartYardCheckBoxView!
    
    @IBOutlet private weak var wantToBreakTheContractContainer: UIView!
    @IBOutlet private weak var wantToBreakTheContractCheckbox: SmartYardCheckBoxView!
    
    @IBOutlet private weak var otherReasonContainer: UIView!
    @IBOutlet private weak var otherReasonCheckbox: SmartYardCheckBoxView!
    
    @IBOutlet private weak var reasonTextContainer: UIView!
    @IBOutlet private weak var reasonTextField: UITextField!
    
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
        bind()
    }
    
    private func bind() {
        let dontWantToManageFromAppGesture = UITapGestureRecognizer()
        dontWantToManageFromAppContainer.addGestureRecognizer(dontWantToManageFromAppGesture)
        
        let wantToBreakTheContractGesture = UITapGestureRecognizer()
        wantToBreakTheContractContainer.addGestureRecognizer(wantToBreakTheContractGesture)
        
        let otherReasonGesture = UITapGestureRecognizer()
        otherReasonContainer.addGestureRecognizer(otherReasonGesture)
        
        let deletionReason = Observable<AddressDeletionReason>
            .merge(
                dontWantToManageFromAppGesture.rx.event.map { _ in .dontWantToManageFromApp },
                wantToBreakTheContractGesture.rx.event.map { _ in .wantToBreakTheContract },
                otherReasonGesture.rx.event.map { _ in .other },
                .just(.dontWantToManageFromApp)
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
        
        let output = viewModel.transform(input)
        
        output.isAbleToDelete
            .drive(deleteButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
    
    private func configureView() {
        let attrString = NSAttributedString(
            string: "Укажите причину",
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
    
    private func selectReason(_ reason: AddressDeletionReason) {
        [dontWantToManageFromAppCheckbox, wantToBreakTheContractCheckbox, otherReasonCheckbox].forEach {
            $0?.setState(state: .uncheckedInactive)
        }
        
        reasonTextField.text = nil
        reasonTextField.sendActions(for: .valueChanged)
        
        switch reason {
        case .dontWantToManageFromApp:
            dontWantToManageFromAppCheckbox.setState(state: .checkedActive)
            
            reasonTextField.resignFirstResponder()
            reasonTextContainer.isHidden = true
            
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
