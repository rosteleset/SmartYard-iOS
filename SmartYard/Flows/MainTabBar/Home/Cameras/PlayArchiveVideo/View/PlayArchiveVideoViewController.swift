//
//  PlayArchiveVideoViewController.swift
//  SmartYard
//
//  Created by admin on 02.06.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class PlayArchiveVideoViewController: BaseViewController {
    
    private let viewModel: PlayArchiveVideoViewModel
    
    init(viewModel: PlayArchiveVideoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
