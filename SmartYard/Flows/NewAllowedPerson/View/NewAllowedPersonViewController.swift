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

class NewAllowedPersonViewController: BaseViewController {

    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var selectFromContactButton: UIButton!
    @IBOutlet private weak var addAccessButton: BlueButton!
    @IBOutlet private weak var mainContainerBottomConstraint: NSLayoutConstraint!
    
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
        view.hideKeyboardWhenTapped = true
        // create the gesture recognizer
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.doSomethingOnTap))
        backgroundView.addGestureRecognizer(tap)
    }

    @objc func doSomethingOnTap() {
        closeTrigger.onNext(())
    }
    
    private func configureView() {
        textField.delegate = self
    }
    
    private func bind() {
        let input = NewAllowedPersonViewModel.Input(
            closeTrigger: closeTrigger.asDriver(onErrorJustReturn: ()),
            selectFromContactTrigger: selectFromContactButton.rx.tap.asDriverOnErrorJustComplete(),
            addAccessTrigger: addAccessButton.rx.tap.asDriverOnErrorJustComplete()
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
