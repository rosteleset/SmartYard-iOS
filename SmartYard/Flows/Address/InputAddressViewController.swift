//
//  InputAddressViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 10.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length

import UIKit
import RxSwift
import RxCocoa
import SearchTextField
import TPKeyboardAvoiding

class InputAddressViewController: BaseViewController {

    @IBOutlet private weak var fakeNavBar: FakeNavBar!
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
//        configureRxKeyboard()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.view.layoutIfNeeded()
        }
        
        // TODO: сейчас кнопка "У меня есть QR-код" закреплена снизу по safe area
        // При переходе на следующий экран, у которого hidesBottomBarWhenPushed, значение инсета снизу меняется
        // При возврате назад, ТОЛЬКО когда мы полностью завершили транзишен до этого экрана, значение меняется обратно
        // В итоге кнопка при возврате назад сначала находится в неправильном месте, как будто таббара тут не существует
        // И только после завершения транзишена она возвращается в нормальное положение
        //
        // Я сделал это изменение положения анимированным, потому что раньше вообще крипово выглядело
        // Нормального решения проблемы НЕТ. Можно будет это закостылить, но пока на мой взгляд не принципиально
    }
    
    private func configureRxKeyboard() {
        RxKeyboard.instance.visibleHeight
            .drive(
                onNext: { [weak self] keyboardVisibleHeight in
                    guard let self = self, keyboardVisibleHeight == 0 else {
                        return
                    }

                    self.scrollView.setContentOffset(
                        CGPoint(x: 0, y: 0),
                        animated: true
                    )
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func bind() {
        streetTextField.rx
            .controlEvent(.editingDidBegin)
            .asDriver()
            .drive(
                onNext: {
//                    self.performScrollUpdate(to: self.streetTextField)
                }
            )
            .disposed(by: disposeBag)
        
        buildingTextField.rx
            .controlEvent(.editingDidBegin)
            .asDriver()
            .drive(
                onNext: {
//                    self.performScrollUpdate(to: self.buildingTextField)
                }
            )
            .disposed(by: disposeBag)
        
        flatTextField.rx
            .controlEvent(.editingDidBegin)
            .asDriver()
            .drive(
                onNext: {
//                    self.performScrollUpdate(to: self.flatTextField)
                }
            )
            .disposed(by: disposeBag)
        
        Observable.of(
            cityTextField.rx.controlEvent(.editingDidBegin),
            streetTextField.rx.controlEvent(.editingDidBegin),
            buildingTextField.rx.controlEvent(.editingDidBegin),
            flatTextField.rx.controlEvent(.editingDidBegin)
            )
            .merge()
            .asDriver(onErrorJustReturn: ())
            .drive(
                onNext: { _ in
//                    self?.scrollView.isScrollEnabled = false
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
                onNext: { _ in
//                    self?.scrollView.isScrollEnabled = true
                }
            )
            .disposed(by: disposeBag)
        
        let input = InputAddressViewModel.Input(
            qrCodeTapped: qrCodeButton.rx.tap.asDriverOnErrorJustComplete(),
            checkServicesTapped: checkAvailableServicesButton.rx.tap.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
            streetsFieldFocused: streetTextField.rx.controlEvent(.editingDidBegin).asDriver(),
            buildingsFieldFocused: buildingTextField.rx.controlEvent(.editingDidBegin).asDriver(),
            flatsFieldFocused: flatTextField.rx.controlEvent(.editingDidBegin).asDriver(),
            inputCityName: cityTextField.rx.text.asDriver(onErrorJustReturn: nil),
            inputStreetName: streetTextField.rx.text.asDriver(onErrorJustReturn: nil),
            inputBuildingName: buildingTextField.rx.text.asDriver(onErrorJustReturn: nil),
            inputFlatName: flatTextField.rx.text.asDriver(onErrorJustReturn: nil)
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
        
        output.isAbleToProceed
            .drive(
                onNext: { [weak self] isAbleToProceed in
                    self?.checkAvailableServicesButton.isEnabled = isAbleToProceed
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
        
        let tapGestureReconizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGestureReconizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureReconizer)
        
        cityTextField.theme.bgColor = .white
        streetTextField.theme.bgColor = .white
        buildingTextField.theme.bgColor = .white
        flatTextField.theme.bgColor = .white
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func performScrollUpdate(to view: UITextField) {
        let desiredOffset = view.frame.origin.y - 80
        
        scrollView.setContentOffset(
            CGPoint(x: 0, y: desiredOffset),
            animated: true
        )
    }
    
}
