//
//  IncomingCallPreviewViewController.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class IncomingCallPreviewViewController: BaseViewController {
    
    @IBOutlet private weak var liveImageView: UIImageView!
    
    let viewModel: IncomingCallPreviewViewModel
    
    init(viewModel: IncomingCallPreviewViewModel) {
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
        let input = IncomingCallPreviewViewModel.Input()
        let output = viewModel.transform(input: input)
        
        output.preview
            .drive(liveImageView.rx.image)
            .disposed(by: disposeBag)
    }
    
}
