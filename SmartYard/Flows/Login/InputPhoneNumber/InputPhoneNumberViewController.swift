//
//  InputPhoneNumberViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 05.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class InputPhoneNumberViewController: BaseViewController {
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var phoneTextView: PhoneTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.hideKeyboardWhenTapped = true
    }
    
}
