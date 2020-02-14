//
//  AddressAccessViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class AddressAccessViewController: UIViewController {

    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var intercomAccessView: IntercomTemporaryAccessView!
    @IBOutlet private weak var barrierAccessView: AccessView!
    @IBOutlet private weak var permanentAccessView: AccessView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

}
