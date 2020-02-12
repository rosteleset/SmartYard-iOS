//
//  ServiceIsNotActivatedViewController.swift
//  SmartYard
//
//  Created by admin on 11/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ServiceIsNotActivatedViewController: BaseViewController {
    
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var sendRequestButton: BlueButton!
    @IBOutlet private weak var backgroundView: UIView!
    
    private let viewModel: ServiceIsNotActivatedViewModel
    
    init(viewModel: ServiceIsNotActivatedViewModel) {
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
        closeButton.setImage(UIImage(named: "CloseIcon"), for: .normal)
        closeButton.setImage(UIImage(named: "CloseIcon")?.darkened(), for: .highlighted)
    }
    
    private func bind() {
        let dismissGesture = UITapGestureRecognizer()
        dismissGesture.cancelsTouchesInView = false
        backgroundView.addGestureRecognizer(dismissGesture)
        
        let dismissTrigger = Driver.merge(
            dismissGesture.rx.event.asDriver().mapToVoid(),
            closeButton.rx.tap.asDriver()
        )
        
        let input = ServiceIsNotActivatedViewModel.Input(
            dismissTrigger: dismissTrigger,
            sendRequestTrigger: sendRequestButton.rx.tap.asDriver()
        )
        
        _ = viewModel.transform(input)
    }
    
}
