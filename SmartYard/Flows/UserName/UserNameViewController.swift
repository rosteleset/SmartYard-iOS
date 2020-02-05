//
//  UserNameViewController.swift
//  SmartYard
//
//  Created by admin on 05/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class UserNameViewController: BaseViewController {

    let viewModel: UserNameViewModel
    
    init(viewModel: UserNameViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
