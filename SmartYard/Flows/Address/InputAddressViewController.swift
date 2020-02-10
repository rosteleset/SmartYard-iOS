//
//  InputAddressViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 10.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class InputAddressViewController: UIViewController {

    @IBOutlet private weak var cityTextField: SmartYardTextField!
    @IBOutlet private weak var streetTextField: SmartYardTextField!
    @IBOutlet private weak var buildingTextField: SmartYardTextField!
    @IBOutlet private weak var flatTextField: SmartYardTextField!
    
    @IBOutlet private weak var checkAvailableServicesButton: BlueButton!
    @IBOutlet private weak var qrCodeButton: ClearButtonWithDashedUnderline!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    private func configureUI() {
        cityTextField.setPlaceholder(string: "Город")
        streetTextField.setPlaceholder(string: "Улица")
        buildingTextField.setPlaceholder(string: "Дом")
        flatTextField.setPlaceholder(string: "Квартира")
        
        qrCodeButton.setLeftAlignment()
        
        view.hideKeyboardWhenTapped = true
    }
    
}
