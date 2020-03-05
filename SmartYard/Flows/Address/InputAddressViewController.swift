//
//  InputAddressViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 10.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import TPKeyboardAvoiding
import RxSwift
import RxCocoa

class InputAddressViewController: BaseViewController {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var cityTextField: SmartYardSearchTextField!
    @IBOutlet private weak var streetTextField: SmartYardSearchTextField!
    @IBOutlet private weak var buildingTextField: SmartYardSearchTextField!
    @IBOutlet private weak var flatTextField: SmartYardSearchTextField!
    @IBOutlet private weak var scrollView: TPKeyboardAvoidingScrollView!
    
    @IBOutlet private weak var checkAvailableServicesButton: BlueButton!
    @IBOutlet private weak var qrCodeButton: ClearButtonWithDashedUnderline!
    
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
        Observable.of(
            cityTextField.rx.controlEvent(.editingDidBegin),
            streetTextField.rx.controlEvent(.editingDidBegin),
            buildingTextField.rx.controlEvent(.editingDidBegin),
            flatTextField.rx.controlEvent(.editingDidBegin)
            )
            .merge()
            .asDriver(onErrorJustReturn: ())
            .drive(
                onNext: { [weak self] _ in
                    self?.scrollView.isScrollEnabled = false
                }
            )
            .disposed(by: disposeBag)
        
        Observable.of(
            cityTextField.rx.controlEvent(.editingDidEnd),
            streetTextField.rx.controlEvent(.editingDidEnd),
            buildingTextField.rx.controlEvent(.editingDidEnd),
            flatTextField.rx.controlEvent(.editingDidEnd)
            )
            .merge()
            .asDriver(onErrorJustReturn: ())
            .drive(
                onNext: { [weak self] _ in
                    self?.scrollView.isScrollEnabled = true
                }
            )
            .disposed(by: disposeBag)
        
        let input = InputAddressViewModel.Input(
            qrCodeTapped: qrCodeButton.rx.tap.asDriverOnErrorJustComplete(),
            checkServicesTapped: checkAvailableServicesButton.rx.tap.asDriverOnErrorJustComplete(),
            inputCityName: cityTextField.rx.text.changed.asDriver(onErrorJustReturn: nil),
            inputStreetName: streetTextField.rx.text.changed.asDriver(onErrorJustReturn: nil),
            inputBuildingName: buildingTextField.rx.text.changed.asDriver(onErrorJustReturn: nil),
            inputFlatName: flatTextField.rx.text.changed.asDriver(onErrorJustReturn: nil)
        )
        
        let output = viewModel.transform(input: input)
        
        output.cities
            .drive(
                onNext: { [weak self] cities in
                    self?.cityTextField.filterStrings(cities)
                }
            )
            .disposed(by: disposeBag)
        
        output.streets
            .drive(
                onNext: { [weak self] streets in
                    self?.streetTextField.filterStrings(streets)
                }
            )
            .disposed(by: disposeBag)
        
        output.buildings
            .drive(
                onNext: { [weak self] buildings in
                    self?.buildingTextField.filterStrings(buildings)
                }
            )
            .disposed(by: disposeBag)
        
        output.flats
            .drive(
                onNext: { [weak self] flats in
                    self?.flatTextField.filterStrings(flats)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureUI() {
        cityTextField.setPlaceholder(string: "Город")
        streetTextField.setPlaceholder(string: "Улица")
        buildingTextField.setPlaceholder(string: "Дом")
        flatTextField.setPlaceholder(string: "Квартира")
        
        qrCodeButton.setLeftAlignment()
        
        view.hideKeyboardWhenTapped = true
        
        cityTextField.theme.bgColor = .white
        streetTextField.theme.bgColor = .white
        buildingTextField.theme.bgColor = .white
        flatTextField.theme.bgColor = .white
    }
    
}
