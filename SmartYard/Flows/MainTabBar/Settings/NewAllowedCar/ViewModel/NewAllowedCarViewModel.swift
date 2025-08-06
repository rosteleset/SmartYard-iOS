//
//  NewAllowedCarViewModel.swift
//  SmartYard
//
//  Created by Александр Попов on 09.07.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

protocol NewAllowedCarViewModelDelegate: AnyObject {
    
    func newAllowedCarViewModelDidAdd(
        _ viewModel: NewAllowedCarViewModel,
        allowedCar: AllowedCar
    )
    
}

final class NewAllowedCarViewModel: BaseViewModel {
    
    private let router: WeakRouter<SettingsRoute>
    
    private let latestAddedCar = BehaviorSubject<AllowedCar?>(value: nil)
    
    private weak var delegate: NewAllowedCarViewModelDelegate?
    
    init(router: WeakRouter<SettingsRoute>, delegate: NewAllowedCarViewModelDelegate) {
        self.router = router
        self.delegate = delegate
    }
    
    func transform(_ input: Input) {
        input.closeTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        input.rawLicencePlaceAddedTrigger
            .distinctUntilChanged()
            .map { licencePlateText -> AllowedCar? in
                let rawText = LicencePlateFormatter.unformat(text: licencePlateText)
                guard !rawText.isEmpty else { return nil }
                
                return AllowedCar(rawNumber: rawText)
            }
            .drive(
                onNext: { [weak self] car in
                    self?.latestAddedCar.onNext(car)
                }
            )
            .disposed(by: disposeBag)
        
        input.addAccessTrigger
            .withLatestFrom(latestAddedCar.asDriver(onErrorJustReturn: nil))
            .ignoreNil()
            .drive(
                onNext: { [weak self] car in
                    guard let self else { return }
                    
                    self.delegate?.newAllowedCarViewModelDidAdd(
                        self,
                        allowedCar: car
                    )
                }
            )
            .disposed(by: disposeBag)
    }
    
}

extension NewAllowedCarViewModel {
    
    struct Input {
        let closeTrigger: Driver<Void>
        let rawLicencePlaceAddedTrigger: Driver<String>
        let addAccessTrigger: Driver<Void>
    }
    
}
