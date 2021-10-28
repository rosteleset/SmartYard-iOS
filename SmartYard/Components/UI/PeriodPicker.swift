//
//  PeriodPicker.swift
//  SmartYard
//
//  Created by Александр Васильев on 27.10.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

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
