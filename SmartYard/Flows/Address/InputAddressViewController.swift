//
//  InputAddressViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 10.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import TPKeyboardAvoiding

class InputAddressViewController: BaseViewController {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var cityTextField: SmartYardTextField!
    @IBOutlet private weak var streetTextField: SmartYardTextField!
    @IBOutlet private weak var buildingTextField: SmartYardTextField!
    @IBOutlet private weak var flatTextField: SmartYardTextField!
    
    @IBOutlet private weak var checkAvailableServicesButton: BlueButton!
    @IBOutlet private weak var qrCodeButton: ClearButtonWithDashedUnderline!
    
    @IBOutlet private weak var scrollView: TPKeyboardAvoidingScrollView!
    
    private let viewModel: InputAddressViewModel
    
    init(viewModel: InputAddressViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        bind()
    }

    private func bind() {
        let input = InputAddressViewModel.Input(
            qrCodeTapped: qrCodeButton.rx.tap.asDriverOnErrorJustComplete(),
            checkServicesTapped: checkAvailableServicesButton.rx.tap.asDriverOnErrorJustComplete()
        )
        
        _ = viewModel.transform(input: input)
    }
    
    private func configureUI() {
        cityTextField.setPlaceholder(string: "Город")
        streetTextField.setPlaceholder(string: "Улица")
        buildingTextField.setPlaceholder(string: "Дом")
        flatTextField.setPlaceholder(string: "Квартира")
        
        qrCodeButton.setLeftAlignment()
        
        view.hideKeyboardWhenTapped = true
    }
    
}
