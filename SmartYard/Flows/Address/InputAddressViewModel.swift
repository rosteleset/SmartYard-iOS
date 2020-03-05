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
    
    private let citiesList = BehaviorSubject<[APILocation]>(value: [])
    private let streetsList = BehaviorSubject<[APIStreet]>(value: [])
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
        let citiesStrings = PublishSubject<[String]>()
        let streetsStrings = PublishSubject<[String]>()
        
        loadCities()
            .ignoreNil()
            .drive(citiesList)
            .disposed(by: disposeBag)
        
        citiesList
            .map { $0.map { $0.name } }
            .asDriver(onErrorJustReturn: [])
            .drive(citiesStrings)
            .disposed(by: disposeBag)
        
        streetsList
            .map { $0.map { $0.name } }
            .asDriver(onErrorJustReturn: [])
            .drive(streetsStrings)
            .disposed(by: disposeBag)
        
        input.inputCityName
            .drive(inputCityName)
            .disposed(by: disposeBag)
        
        input.inputStreetName
            .drive(inputStreetName)
            .disposed(by: disposeBag)
        
        input.inputFlatName
            .drive(inputFlatName)
            .disposed(by: disposeBag)
        
        input.inputBuildingName
            .drive(inputBuildingName)
            .disposed(by: disposeBag)
        
        input.streetsFieldFocused
            .withLatestFrom(inputCityName.asDriver(onErrorJustReturn: nil))
            .ignoreNil()
            .flatMapLatest { [weak self] city -> Driver<GetStreetsResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.loadStreets(by: city).asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(streetsList)
            .disposed(by: disposeBag)
        
        input.buildingsFieldFocused
            .withLatestFrom(inputStreetName.asDriver(onErrorJustReturn: nil))
            .ignoreNil()
            .flatMapLatest { [weak self] street -> Driver<GetHousesResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.loadBuildings(by: street)
            }
            .ignoreNil()
            .map { $0.map { $0.number } }
            .asDriver(onErrorJustReturn: [])
            .drive(buildingsList)
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
            cities: citiesStrings.asDriver(onErrorJustReturn: []),
            streets: streetsStrings.asDriver(onErrorJustReturn: []),
            buildings: buildingsList.asDriver(onErrorJustReturn: []),
            flats: flatsList.asDriver(onErrorJustReturn: [])
        )
    }
    
    private func loadCities() -> Driver<GetAllLocationsResponseData?> {
        return apiWrapper.getAllLocations().asDriver(onErrorJustReturn: nil)
    }
    
    private func loadStreets(by inputCity: String) -> Driver<GetStreetsResponseData?> {
        guard let data = try? citiesList.value(),
              let city = data.first(where: { $0.name == inputCity })
        else {
            return .empty()
        }
        
        return apiWrapper.getStreetsByLocation(locationId: city.locationId).asDriver(onErrorJustReturn: nil)
    }
    
    private func loadBuildings(by inputStreet: String) -> Driver<GetHousesResponseData?> {
        guard let data = try? streetsList.value(),
            let street = data.first(where: { $0.name == inputStreet })
            else {
                return .empty()
            }
        
        return apiWrapper.getHousesByStreet(streetId: street.streetId).asDriver(onErrorJustReturn: nil)
    }
}

extension InputAddressViewModel {
    
    struct Input {
        let qrCodeTapped: Driver<Void>
        let checkServicesTapped: Driver<Void>
        
        let streetsFieldFocused: Driver<Void>
        let buildingsFieldFocused: Driver<Void>
        let flatsFieldFocused: Driver<Void>
        
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

