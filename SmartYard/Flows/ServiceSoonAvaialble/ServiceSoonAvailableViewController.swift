//
//  ServiceSoonAvailableViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 13.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class ServiceSoonAvailableViewController: BaseViewController {

    @IBOutlet private weak var titleImageView: UIImageView!
    @IBOutlet private weak var hintLabel: UILabel!
    @IBOutlet private weak var qrCodeButton: BlueButton!
    @IBOutlet private weak var actionButton: WhiteButtonWithBorder!
    
    private let viewModel: ServiceSoonAvailableViewModel
    
    init(viewModel: ServiceSoonAvailableViewModel) {
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
        let input = ServiceSoonAvailableViewModel.Input(
            qrCodeTapped: qrCodeButton.rx.tap.asDriverOnErrorJustComplete(),
            actionTapped: actionButton.rx.tap.asDriverOnErrorJustComplete(),
            viewWillAppearTrigger: rx.viewWillAppear.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input: input)
        
        output.actionTextTrigger
            .drive(
                onNext: { [weak self] text in
                    self?.actionButton.setTitle(text, for: .normal)
                }
            )
            .disposed(by: disposeBag)
        
        output.changeVisibilityQrCodeElementsTrigger
            .drive(
                onNext: { [weak self] shouldHide in
                    self?.qrCodeButton.isHidden = shouldHide
                }
            )
            .disposed(by: disposeBag)
        
        output.hintTextTrigger
            .drive(hintLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.titleImageTrigger
            .drive(titleImageView.rx.image)
            .disposed(by: disposeBag)
    }

}
