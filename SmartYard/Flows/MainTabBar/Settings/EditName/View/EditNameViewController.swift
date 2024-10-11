//
//  EditNameViewController.swift
//  SmartYard
//
//  Created by admin on 27/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import JGProgressHUD

class EditNameViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var nameTextField: SmartYardTextField!
    @IBOutlet private weak var middleNameTextField: SmartYardTextField!
    @IBOutlet private weak var saveButton: UIButton!
    @IBOutlet private weak var backgroundView: UIView!
    
    @IBOutlet private var mainContainerBottomConstraint: NSLayoutConstraint!
    
    private let viewModel: EditNameViewModel
    private let preloadedName: APIClientName?
    
    var loader: JGProgressHUD?
    
    init(viewModel: EditNameViewModel, preloadedName: APIClientName?) {
        self.viewModel = viewModel
        self.preloadedName = preloadedName
        
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
        
        nameTextField.setPlaceholder(string: "Имя", isRequiredField: true)
        nameTextField.delegate = self
        nameTextField.text = preloadedName?.name
        nameTextField.sendActions(for: .allEditingEvents)
        
        middleNameTextField.setPlaceholder(string: "Отчество")
        middleNameTextField.delegate = self
        middleNameTextField.text = preloadedName?.patronymic
        middleNameTextField.sendActions(for: .allEditingEvents)
    }
    
    private func configureRxKeyboard() {
        // MARK: Здесь был пролаг (не было анимации) если экран был первым при запуске приложения
        // Пришлось закастомить RxKeyboard и проксировать параметры анимации, чтобы точно восстановить их
        
        RxKeyboard.instance.visibleHeight
            .debounce(.milliseconds(50))
            .withLatestFrom(RxKeyboard.instance.curve.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .withLatestFrom(RxKeyboard.instance.duration.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (firstPack, duration) = args
                    let (keyboardVisibleHeight, curve) = firstPack
                    
                    guard let self = self else {
                        return
                    }
                    
                    self.mainContainerBottomConstraint.constant = (keyboardVisibleHeight == 0) || (self.view.frame.height == keyboardVisibleHeight) ?
                        0 :
                    keyboardVisibleHeight
                    
                    UIView.beginAnimations(nil, context: nil)
                    UIView.setAnimationCurve(curve ?? .linear)
                    UIView.setAnimationDuration(duration ?? 0.25)
                    self.view.layoutIfNeeded()
                    UIView.commitAnimations()
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func bind() {
        let dismissGesture = UITapGestureRecognizer()
        dismissGesture.cancelsTouchesInView = false
        backgroundView.addGestureRecognizer(dismissGesture)
        
        let input = EditNameViewModel.Input(
            name: nameTextField.rx.text.asDriver(),
            middleName: middleNameTextField.rx.text.asDriver(),
            dismissTrigger: dismissGesture.rx.event.asDriver().mapToVoid(),
            saveTrigger: saveButton.rx.tap.asDriver()
        )
        
        let output = viewModel.transform(input: input)
        
        output.isAbleToSave
            .drive(saveButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    if isLoading {
                        self?.view.endEditing(true)
                    }
                    
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
        
        output.prepareTransitionTrigger
            .drive(
                onNext: { [weak self] in
                    self?.view.endEditing(true)
                    self?.view.isUserInteractionEnabled = false
                }
            )
            .disposed(by: disposeBag)
    }
    
}

extension EditNameViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
}
