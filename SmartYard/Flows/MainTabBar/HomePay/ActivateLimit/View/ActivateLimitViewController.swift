//
//  ActivateLimitViewController.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 17.09.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import XCoordinator

class ActivateLimitViewController: BaseViewController {
    
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var activateButton: UIButton!
    
    private let viewModel: ActivateLimitViewModel
    
    init(viewModel: ActivateLimitViewModel) {
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // imageView.sizeToFit()
    }
    
    private func bind() {
        
        let input = ActivateLimitViewModel.Input(
            closeButtonTapped: cancelButton.rx.tap.asDriverOnErrorJustComplete(),
            activateButtonTapped: activateButton.rx.tap.asDriverOnErrorJustComplete()
        )

        viewModel.transform(input: input)

    }
}
