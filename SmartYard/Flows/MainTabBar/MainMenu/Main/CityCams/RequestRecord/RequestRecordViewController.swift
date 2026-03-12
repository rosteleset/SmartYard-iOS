//
//  RequestRecordViewController.swift
//  SmartYard
//
//  Created by Александр Васильев on 19.02.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import JGProgressHUD
import TPKeyboardAvoiding
import RxSwift

final class RequestRecordViewController: BaseViewController, LoaderPresentable, UIPickerViewDelegate {
    var loader: JGProgressHUD?
    private let viewModel: RequestRecordViewModel

    @IBOutlet private weak var headerView: HeaderView!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var topRoundedView: UIView!
    @IBOutlet private weak var scrollView: TPKeyboardAvoidingScrollView!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var dateTextField: SmartYardBorderedTextField!
    @IBOutlet private weak var hoursTextField: SmartYardBorderedTextField!
    @IBOutlet private weak var minutesTextField: SmartYardBorderedTextField!
    @IBOutlet private weak var durationTextField: SmartYardBorderedTextField!
    @IBOutlet private weak var notesTextField: SmartYardBorderedTextField!
    @IBOutlet private weak var durationHintLabel: UILabel!
    @IBOutlet private weak var processingHintLabel: UILabel!
    private var datePicker: UIDatePicker
    private var periodPicker: PeriodPicker
    private var selectedDate: Date
    private var periodProxy = BehaviorSubject<Int>(value: 10)
    
    init(viewModel: RequestRecordViewModel) {
        self.viewModel = viewModel
        
        datePicker = UIDatePicker()
        
        // по умолчанию на iOS 14+ выбирается .compact режим, который конфликтует с tabbar
        // проще всего это фиксится принудительным выставлением стиля в "wheels"
        if #available(iOS 13.4, *) {
            self.datePicker.preferredDatePickerStyle = .wheels
        }
        
        periodPicker = PeriodPicker()
        selectedDate = Date()
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }
    private func bind() {
        
        let output = viewModel.transform(
                RequestRecordViewModel.Input(
                    backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
                    sendRequestTrigger: button.rx.tap.asDriver(),
                    date: datePicker.rx.date.asDriver(),
                    duration: periodProxy.asDriver(onErrorJustReturn: 10),
                    notes: notesTextField.rx.text.asDriver()
                )
            )

        headerView.setText(
            L10n.Camera.City.requestRecordButton,
            subtitle: output.camera.name
        )
    }
    fileprivate func configureUI() {
        hoursTextField.text = L10n.Camera.RecordRequest.timeHoursPlaceholder
        minutesTextField.text = L10n.Camera.RecordRequest.timeMinutesPlaceholder
        dateTextField.text = L10n.Camera.RecordRequest.datePlaceholder
        durationTextField.text = L10n.Camera.RecordRequest.durationPlaceholder
        notesTextField.placeholder = L10n.Camera.RecordRequest.commentPlaceholder
        durationHintLabel.text = L10n.Camera.RecordRequest.durationHint
        processingHintLabel.text = L10n.Camera.RecordRequest.processingHint
        button.setTitle(L10n.Camera.RecordRequest.sendRequestButton, for: .normal)
        fakeNavBar.setText(L10n.Camera.City.publicCamerasTitle)

        view.hideKeyboardWhenTapped = true
        
        // готовим toolbar для пикеров
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexSpace, doneButton], animated: false)
        
        // Настраиваем DatePicker для поля Дата
        datePicker.date = selectedDate
        datePicker.datePickerMode = .dateAndTime
        datePicker.maximumDate = Date()
        datePicker.minimumDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())
        
        dateTextField.inputAccessoryView = toolbar
        dateTextField.inputView = datePicker
        dateTextField.tintColor = UIColor.clear
        
        // добавляем DatePicker для полей Часы и Минуты
        hoursTextField.inputAccessoryView = toolbar
        hoursTextField.inputView = datePicker
        hoursTextField.tintColor = UIColor.clear
        
        minutesTextField.inputAccessoryView = toolbar
        minutesTextField.inputView = datePicker
        minutesTextField.tintColor = UIColor.clear
        
        datePicker.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
        
        periodPicker.setCallback(callback: selectPeriodAction(_:))
        selectPeriodAction(10)
        durationTextField.inputView = periodPicker
        durationTextField.inputAccessoryView = toolbar
        durationTextField.tintColor = UIColor.clear
        
        // Обновляем значения полей значениями по умолчанию
        getValueFromPicker()
        
    }
}

extension RequestRecordViewController {

    @objc func doneAction() {
        view.endEditing(true)
    }
    
    @objc func valueChanged() {
        getValueFromPicker()
    }
    
    func getValueFromPicker() {
        selectedDate = datePicker.date
        
        let formatter = DateFormatter()
        
        formatter.dateFormat = "d.MM.yyyy"
        let dateString = formatter.string(from: selectedDate)
        
        formatter.dateFormat = "HH"
        let hourString = formatter.string(from: selectedDate)
        
        formatter.dateFormat = "mm"
        let minuteString = formatter.string(from: selectedDate)
        
        let dateLabel = L10n.Camera.RecordRequest.dateLabel
        let timeLabel = L10n.Camera.RecordRequest.timeLabel
        let hourSuffix = L10n.Common.Time.hoursShort
        let minuteSuffix = L10n.Common.Time.minutesShort
        
        dateTextField.text = "\(dateLabel): \(dateString)"
        hoursTextField.text = "\(timeLabel): \(hourString) \(hourSuffix)"
        minutesTextField.text = "\(minuteString) \(minuteSuffix)"
    }

    func selectPeriodAction(_ value: Int) {
        let durationLabel = L10n.Camera.RecordRequest.durationLabel
        let minuteSuffix = L10n.Common.Time.minutesShort
        
        durationTextField.text = "\(durationLabel): \(value) \(minuteSuffix)"
        periodProxy.onNext(value)
    }
    
}

