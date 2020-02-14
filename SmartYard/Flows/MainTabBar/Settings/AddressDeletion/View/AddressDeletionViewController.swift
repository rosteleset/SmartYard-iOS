//
//  AddressDeletionViewController.swift
//  SmartYard
//
//  Created by admin on 14/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AddressDeletionViewController: BaseViewController {
    
    @IBOutlet private weak var deleteButton: BlueButton!
    @IBOutlet private weak var cancelButton: UIButton!
    
    private let viewModel: AddressDeletionViewModel
    
    init(viewModel: AddressDeletionViewModel) {
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
        let input = AddressDeletionViewModel.Input(
            cancelTrigger: cancelButton.rx.tap.asDriver(),
            deleteTrigger: deleteButton.rx.tap.asDriver(),
            deletionReason: .just(.dontWantToManageFromApp)
        )
        
        _ = viewModel.transform(input)
    }

}
