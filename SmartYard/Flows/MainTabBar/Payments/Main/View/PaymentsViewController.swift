//
//  PaymentsViewController.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PaymentsViewController: BaseViewController {

    let viewModel: PaymentsViewModel
    
    init(viewModel: PaymentsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
