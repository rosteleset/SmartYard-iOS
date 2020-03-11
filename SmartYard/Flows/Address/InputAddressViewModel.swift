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
    private var loadedBuildings = [String: [APIHouse]]()
    
    private let flatsList = BehaviorSubject<[String]>(value: [])
    
    init(router: WeakRouter<HomeRoute>, apiWrapper: APIWrapper) {
        self.router = router
        self.apiWrapper = apiWrapper
    }
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
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
                
                guard let cachedBuildings = self.loadedBuildings[street.name] else {
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
                    self?.loadedBuildings[street.name] = buildings
                }
            )
            .drive(
                onNext: { [weak self] args in
                    let (buildings, _) = args
                    self?.buildingsList.onNext(buildings.map { $0.number })
                }
            )
            .disposed(by: disposeBag)

        input.qrCodeTapped
            .drive(
                onNext: {
                    // TODO
                }
            )
            .disposed(by: disposeBag)
        
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        let requestData = input.checkServicesTapped.withLatestFrom(
            Driver
                .combineLatest(
                    input.inputCityName,
                    input.inputStreetName,
                    input.inputBuildingName,
                    input.inputFlatName
                )
            )
            .flatMap { [weak self] args -> Driver<(String, String?)> in
                let (cityName, streetName, buildingName, flatName) = args
                
                guard let self = self,
                    let uCityName = cityName?.trimmed, !uCityName.isEmpty,
                    let uStreetName = streetName?.trimmed, !uStreetName.isEmpty,
                    let uBuildingName = buildingName?.trimmed, !uBuildingName.isEmpty else {
                    return .empty()
                }
                
                var addressString = [uCityName, uStreetName, uBuildingName].joined(separator: ", ")
                
                if let uFlatName = flatName?.trimmed, !uFlatName.isEmpty {
                    addressString += ", \(uFlatName)"
                }
                
                guard let buildings = self.loadedBuildings[uStreetName] else {
                    return .just((addressString, nil))
                }
                
                let houseId = buildings.first { $0.number == uBuildingName }?.houseId
                
                return .just((addressString, houseId))
            }
        
        let withoutHouseId = requestData.flatMap { args -> Driver<String> in
            let (address, houseId) = args
            
            guard houseId == nil else {
                return .empty()
            }
            
            return .just(address)
        }
        
        withoutHouseId
            .drive(
                onNext: { [weak self] _ in
                    self?.router.trigger(.unavailableServices)
                }
            )
            .disposed(by: disposeBag)

        let withHouseId = requestData
            .flatMap { args -> Driver<(String, String)> in
                let (address, houseId) = args
                
                guard let uHouseId = houseId else {
                    return .empty()
                }
                
                return .just((address, uHouseId))
            }
        
        withHouseId
            .flatMapLatest { [weak self] args -> Driver<(String, GetServicesResponseData?)?> in
                guard let self = self else {
                    return .just(nil)
                }

                let (address, houseId) = args

                return self.apiWrapper.getServicesByHouseId(houseId: houseId)
                    .map {
                        guard let response = $0 else {
                            return nil
                        }

                        return (address, response)
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] args in
                    let (address, response) = args

                    guard let self = self, let services = response else {
                        return
                    }

                    guard !services.isEmpty else {
                        self.router.trigger(.unavailableServices)
                        return
                    }

                    self.router.trigger(
                        .availableServices(
                            address: address,
                            services: services
                        )
                    )
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
        let backTrigger: Driver<Void>
        
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

