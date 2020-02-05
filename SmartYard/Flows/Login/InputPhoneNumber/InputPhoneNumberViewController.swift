//
//  InputPhoneNumberViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 05.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import PinCodeTextField

class InputPhoneNumberViewController: BaseViewController {

    @IBOutlet weak var phoneTextField: PinCodeTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        phoneTextField.delegate = self
    }

}

extension InputPhoneNumberViewController: PinCodeTextFieldDelegate {
    
}
