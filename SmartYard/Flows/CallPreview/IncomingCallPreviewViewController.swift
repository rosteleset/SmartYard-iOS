//
//  IncomingCallPreviewViewController.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class IncomingCallPreviewViewController: BaseViewController {

    let viewModel: IncomingCallPreviewViewModel
    
    init(viewModel: IncomingCallPreviewViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
