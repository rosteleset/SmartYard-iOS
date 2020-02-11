//
//  AddressSettingsViewController.swift
//  SmartYard
//
//  Created by admin on 11/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class AddressSettingsViewController: BaseViewController {
    
    @IBOutlet private weak var fakeNavBar: FakeNavBar!

    private let viewModel: AddressSettingsViewModel
    
    init(viewModel: AddressSettingsViewModel) {
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
    
    private func bind() {
        let input = AddressSettingsViewModel.Input(backTrigger: fakeNavBar.rx.backButtonTap.asDriver())
        
        _ = viewModel.transform(input)
    }

}
