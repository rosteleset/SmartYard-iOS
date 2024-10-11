//
//  SendDetailsViewController.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 26.06.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import JGProgressHUD
import JTAppleCalendar

class SendDetailsViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var rangeTextField: SmartYardTextField!
    @IBOutlet private weak var emailTextField: SmartYardTextField!
    @IBOutlet private weak var sendButton: BlueButton!
    @IBOutlet private weak var rangeButton: UIButton!
    @IBOutlet private weak var backgroundView: UIView!
    
    @IBOutlet private var mainContainerBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var calendarBackView: UIView!
    @IBOutlet weak var calendarContainerView: UIView!
    @IBOutlet weak var calendarView: JTACMonthView!
    @IBOutlet weak var calendarRangeLabel: UILabel!
    @IBOutlet weak var calendarMonthLabel: UILabel!
    @IBOutlet weak var calendarYearLabel: UILabel!
    @IBOutlet weak var calendarLeftArrowButton: UIButton!
    @IBOutlet weak var calendarRightArrowButton: UIButton!

    @IBAction private func tapShowCalendar() {
        guard let contract = range?.contract, let fromDay = range?.fromDay, let toDay = range?.toDay else {
            return
        }
        showCalendar(contract: contract, from: fromDay, to: toDay)
    }
    
    var calendarRangeSelect: DetailRange?
    let calendarRange = CalendarDateRange(
        period: 3,
        component: .year,
        to: Date()
    )

    private let viewModel: SendDetailsViewModel
    private var range: DetailRange?
    
    let rangeTrigger = PublishSubject<DetailRange?>()

    var loader: JGProgressHUD?
    
    init(viewModel: SendDetailsViewModel, range: DetailRange) {
        self.viewModel = viewModel
        self.range = range
        
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureCalendar()
        configureRxKeyboard()
        bind()
        rangeTrigger.onNext(range)
    }
    
    private func configureView() {
        view.hideKeyboardWhenTapped = true
        
        emailTextField.setPlaceholder(string: "", isRequiredField: true)
        emailTextField.delegate = self
        emailTextField.sendActions(for: .allEditingEvents)

        rangeTextField.setPlaceholder(string: "", isRequiredField: true)
        rangeTextField.delegate = self
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
    
    private func bind() {
        let dismissGesture = UITapGestureRecognizer()
        dismissGesture.cancelsTouchesInView = false
        backgroundView.addGestureRecognizer(dismissGesture)
            
        rangeTrigger
            .asDriver(onErrorJustReturn: nil)
            .drive(
                onNext: { [weak self] range in
                    guard let self = self, let range = range else {
                        return
                    }
                    
                    self.range = range
                    
                    let formatter = DateFormatter()

                    formatter.timeZone = Calendar.novokuznetskCalendar.timeZone
                    formatter.dateFormat = "dd.MM.yyyy"
                    
                    self.rangeTextField.text = formatter.string(from: range.fromDay!) + " - " + formatter.string(from: range.toDay!)
                }
            )
            .disposed(by: disposeBag)
        
        let input = SendDetailsViewModel.Input(
            range: rangeTrigger.asDriver(onErrorJustReturn: nil),
            email: emailTextField.rx.text.asDriver(),
            dismissTrigger: dismissGesture.rx.event.asDriver().mapToVoid(),
            sendTrigger: sendButton.rx.tap.asDriver()
        )
        
        let output = viewModel.transform(input: input)
        
        output.isAbleToSend
            .drive(
                onNext: { [weak self] isAbleToSend in
                    self?.sendButton.isEnabled = isAbleToSend
                }
            )
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
    }
    
}

extension SendDetailsViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard textField == emailTextField else {
            return false
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailTextField: emailTextField.resignFirstResponder()
        default: break
        }

        return true
    }
    
}
