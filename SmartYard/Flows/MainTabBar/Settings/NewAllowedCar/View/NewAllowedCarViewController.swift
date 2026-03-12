//
//  NewAllowedCarViewModel.swift
//  SmartYard
//
//  Created by Александр Попов on 09.07.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ContactsUI
import Contacts
import SHSPhoneComponent

final class NewAllowedCarViewController: BaseViewController {
    
    // swiftlint:disable all
    @IBOutlet weak var textField: SmartYardLicensePlateTextField!
    // swiftlint:enable all
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var carNumberHintLabel: UILabel!
    private let viewModel: NewAllowedCarViewModel
    
    init(viewModel: NewAllowedCarViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        titleLabel.text = L10n.Settings.ShareCar.shareAccess
        textField.placeholder = L10n.Settings.ShareCar.platePlaceholder
        carNumberHintLabel.text = L10n.Settings.ShareCar.subtitle
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        view.hideKeyboardWhenTapped = true
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textField.becomeFirstResponder()
    }
    
    private func bind() {
        let dismissTap = UITapGestureRecognizer()
        backgroundView.addGestureRecognizer(dismissTap)

        let rawLicencePlaceAddedTrigger = textField.shareButtonTapped
            .map { [weak self] in
                self?.textField.text ?? ""
            }
            .asDriver(onErrorJustReturn: "")
        
        let input = NewAllowedCarViewModel.Input(
            closeTrigger: dismissTap.rx.event.mapToVoid().asDriver(onErrorJustReturn: ()),
            rawLicencePlaceAddedTrigger: rawLicencePlaceAddedTrigger,
            addAccessTrigger: textField.shareButtonTapped
        )
        
        viewModel.transform(input)
    }
    
}

