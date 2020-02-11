//
//  AddressConfirmationViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 11.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class AddressConfirmationViewController: BaseViewController {
    
    @IBOutlet private weak var segmentControl: SmartYardSegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        segmentControl.segmentItems = ["Через курьера", "Визит в офис"]
    }
    
}
