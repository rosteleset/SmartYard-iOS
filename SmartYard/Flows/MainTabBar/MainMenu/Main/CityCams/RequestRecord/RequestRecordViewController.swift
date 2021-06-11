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

class RequestRecordViewController: BaseViewController, LoaderPresentable, UIPickerViewDelegate {
    var loader: JGProgressHUD?
    private let viewModel: RequestRecordViewModel
    
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var buttonConstraint: NSLayoutConstraint!
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var topRoundedView: UIView!
    @IBOutlet private weak var scrollView: TPKeyboardAvoidingScrollView!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var dateTextField: SmartYardTextField!
    @IBOutlet private weak var hoursTextField: SmartYardTextField!
    @IBOutlet private weak var minutesTextField: SmartYardTextField!
    @IBOutlet private weak var durationTextField: SmartYardTextField!
    @IBOutlet private weak var notesTextField: SmartYardTextField!
    
    private var datePicker: UIDatePicker
    private var periodPicker : PeriodPicker
    private var selectedDate: Date
    private var periodProxy = BehaviorSubject<Int>(value: 10)
    
    init(viewModel: RequestRecordViewModel) {
        self.viewModel = viewModel
        
        datePicker = UIDatePicker()
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
        configureView()
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
        addressLabel.text = output.camera.name
    }
    fileprivate func configureView() {
        fakeNavBar.setText("Городские камеры")
        view.hideKeyboardWhenTapped = true
        
        //готовим toolbar для пикеров
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexSpace, doneButton], animated: false)
        
        //Настраиваем DatePicker для поля Дата
        datePicker.date = selectedDate
        datePicker.datePickerMode = .dateAndTime
        datePicker.maximumDate = Date()
        datePicker.minimumDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())
        
        dateTextField.inputAccessoryView = toolbar
        dateTextField.inputView = datePicker
        dateTextField.tintColor = UIColor.clear
        
        //добавляем DatePicker для полей Часы и Минуты
        hoursTextField.inputAccessoryView = toolbar
        hoursTextField.inputView = datePicker
        hoursTextField.tintColor = UIColor.clear
        
        minutesTextField.inputAccessoryView = toolbar
        minutesTextField.inputView = datePicker
        minutesTextField.tintColor = UIColor.clear
        
        datePicker.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
        
        periodPicker.setCallback(callback: selectPeriodAction(_:))
        durationTextField.inputView = periodPicker
        durationTextField.inputAccessoryView = toolbar
        durationTextField.tintColor = UIColor.clear
        
        //Обновляем значения полей значениями по умолчанию
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
        let formater = DateFormatter()
        
        selectedDate = datePicker.date
        
        formater.dateFormat = "d.MM.yyyy"
        dateTextField.text = "Дата записи: \(formater.string(from: selectedDate))"
        formater.dateFormat = "HH"
        hoursTextField.text = "Время: \(formater.string(from: selectedDate)) ч"
        formater.dateFormat = "mm"
        minutesTextField.text = "\(formater.string(from: selectedDate)) мин"
    }
    
    func selectPeriodAction(_ value: Int)
    {
        durationTextField.text = "Продолжительность: \(value)"
        periodProxy.onNext(value)
    }
    
}

class PeriodPicker: UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate {
    private let pickerData = ["10 минут", "20 минут", "30 минут", "40 минут", "50 минут", "60 минут"]
    private let pickerRawValue = [10, 20, 30, 40, 50, 60]
    private var callback: ((_ value: Int) -> Void)?
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let callback = callback else {
            return
        }
        callback(pickerRawValue[row])
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.dataSource = self
        (self as UIPickerView).delegate = self
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCallback(callback: @escaping (_ value: Int) -> Void) {
        self.callback = callback
    }
}
