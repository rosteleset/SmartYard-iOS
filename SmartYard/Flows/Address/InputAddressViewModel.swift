//
//  InputAddressViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 10.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxCocoa

class InputAddressViewModel: BaseViewModel {
    
    private let router: WeakRouter<HomeRoute>
    private let apiWrapper: APIWrapper
    
    private let citiesList = BehaviorSubject<[String]>(value: [])
    private let streetsList = BehaviorSubject<[String]>(value: [])
    private let buildingsList = BehaviorSubject<[String]>(value: [])
    private let flatsList = BehaviorSubject<[String]>(value: [])
    
    private let inputCityName = BehaviorSubject<String?>(value: nil)
    private let inputStreetName = BehaviorSubject<String?>(value: nil)
    private let inputBuildingName = BehaviorSubject<String?>(value: nil)
    private let inputFlatName = BehaviorSubject<String?>(value: nil)
    
    init(router: WeakRouter<HomeRoute>, apiWrapper: APIWrapper) {
        self.router = router
        self.apiWrapper = apiWrapper
    }
    
    func transform(input: Input) -> Output {
        loadCities()
            .ignoreNil()
            .flatMapLatest { response -> Driver<[String]> in
                Observable<[String]>
                    .just(response.map { $0.name })
                    .asDriver(onErrorJustReturn: [])
            }
            .drive(citiesList)
            .disposed(by: disposeBag)
        
        input.qrCodeTapped
            .drive(
                onNext: {
                    // TODO
                }
            )
            .disposed(by: disposeBag)
        
        input.checkServicesTapped
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.availableServices)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            cities: citiesList.asDriver(onErrorJustReturn: []),
            streets: streetsList.asDriver(onErrorJustReturn: []),
            buildings: buildingsList.asDriver(onErrorJustReturn: []),
            flats: flatsList.asDriver(onErrorJustReturn: [])
        )
    }
    
    private func loadCities() -> Driver<GetAllLocationsResponseData?> {
        return apiWrapper.getAllLocations().asDriver(onErrorJustReturn: nil)
    }
    
//    private func loadStreets(by inputCity: String) -> Driver<GetStreetsResponseData?> {
//        return apiWrapper.getStreetsByLocation(locationId: <#T##String#>)
//    }
    
}

extension InputAddressViewModel {
    
    struct Input {
        let qrCodeTapped: Driver<Void>
        let checkServicesTapped: Driver<Void>
        
        let inputCityName: Driver<String?>
        let inputStreetName: Driver<String?>
        let inputBuildingName: Driver<String?>
        let inputFlatName: Driver<String?>
    }
    
    struct Output {
        let cities: Driver<[String]>
        let streets: Driver<[String]>
        let buildings: Driver<[String]>
        let flats: Driver<[String]>
    }
    
}

