//
//  NotificationsViewController.swift
//  SmartYard
//
//  Created by admin on 23/03/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class NotificationsViewController: BaseViewController {

    private let viewModel: NotificationsViewModel
    
    init(viewModel: NotificationsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
        bind()
    }
    
    private func configureView() {
        
    }
    
    private func bind() {
        
    }

}
