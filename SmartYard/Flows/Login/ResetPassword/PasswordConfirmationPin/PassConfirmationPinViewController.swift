//
//  PassConfirmationPinViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 23.03.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PassConfirmationPinViewController: BaseViewController {

    private let viewModel: PassConfirmationPinViewModel
    
    init(viewModel: PassConfirmationPinViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

}
