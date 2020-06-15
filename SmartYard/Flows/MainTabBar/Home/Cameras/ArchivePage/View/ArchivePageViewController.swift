//
//  ArchivePageViewController.swift
//  SmartYard
//
//  Created by admin on 15.06.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ArchivePageViewController: BaseViewController {
    
    private let viewModel: ArchivePageViewModel
    
    init(viewModel: ArchivePageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bind()
    }

    func bind() {
        let input = ArchivePageViewModel.Input()
        let output = viewModel.transform(input)
    }
    
}
