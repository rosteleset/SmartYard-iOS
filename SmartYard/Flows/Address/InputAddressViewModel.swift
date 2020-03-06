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
    
    private var loadedStreets = [String: [APIStreet]]()
    private var loadedBuilinds = [String: [APIHouse]]()
    
    private let flatsList = BehaviorSubject<[String]>(value: [])
    
    init(router: WeakRouter<HomeRoute>, apiWrapper: APIWrapper) {
        self.router = router
        self.apiWrapper = apiWrapper
    }
    
    func transform(input: Input) -> Output {
        apiWrapper.getAllLocations()
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(citiesList)
            .disposed(by: disposeBag)
        
        input.streetsFieldFocused
            .withLatestFrom(input.inputCityName.asDriver(onErrorJustReturn: nil))
            .withLatestFrom(citiesList.asDriver(onErrorJustReturn: [])) { ($0, $1) }
            .flatMapLatest { [weak self] args -> Driver<(GetStreetsResponseData, APILocation)?> in
                let (cityName, cities) = args
                
                guard let self = self, let city = (cities.first { $0.name == cityName }) else {
                    return .empty()
                }

                guard let cachedStreets = self.loadedStreets[city.name] else {
                    return self.apiWrapper.getStreetsByLocation(locationId: city.locationId)
                        .map {
                            guard let response = $0 else {
                                return nil
                            }
                            
                            return (response, city)
                        }
                        .asDriver(onErrorJustReturn: nil)
                }
                
                return .just((cachedStreets, city))
            }
            .ignoreNil()
            .do(
                onNext: { [weak self] args in
                    let (streets, city) = args
                    self?.loadedStreets[city.name] = streets
                }
            )
            .drive(
                onNext: { [weak self] args in
                    let (streets, _) = args
                    self?.streetsList.onNext(streets)
                }
            )
            .disposed(by: disposeBag)

        input.buildingsFieldFocused
            .withLatestFrom(input.inputStreetName.asDriver(onErrorJustReturn: nil))
            .withLatestFrom(streetsList.asDriverOnErrorJustComplete()) { ($0, $1) }
            .flatMapLatest { [weak self] args -> Driver<(GetHousesResponseData, APIStreet)?> in
                let (streetName, streets) = args
                
                guard let self = self, let street = (streets.first { $0.name == streetName }) else {
                    return .empty()
                }
                
                guard let cachedBuildings = self.loadedBuilinds[street.name] else {
                    return self.apiWrapper.getHousesByStreet(streetId: street.streetId)
                        .map {
                            guard let response = $0 else {
                                return nil
                            }
                            
                            return (response, street)
                        }
                        .asDriver(onErrorJustReturn: nil)
                }
                
                return .just((cachedBuildings, street))
            }
            .ignoreNil()
            .do(
                onNext: { [weak self] args in
                    let (buildings, street) = args
                    self?.loadedBuilinds[street.name] = buildings
                }
            )
            .flatMap { args -> Driver<[String]> in
                let (buildings, _) = args
                let buildingNumbers = buildings.map { $0.number }
                return .just(buildingNumbers)
            }
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
            cities: citiesList.asDriver(onErrorJustReturn: [])
                .map { $0.map { $0.name } },
            streets: streetsList.asDriver(onErrorJustReturn: [])
                .map { $0.map { $0.name } },
            buildings: buildingsList.asDriver(onErrorJustReturn: []),
            flats: flatsList.asDriver(onErrorJustReturn: [])
        )
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

