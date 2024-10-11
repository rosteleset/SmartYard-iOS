//
//  InputAddressViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 10.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable type_body_length function_body_length cyclomatic_complexity file_length

import Foundation
import XCoordinator
import RxSwift
import RxCocoa
import AVFoundation

class InputAddressViewModel: BaseViewModel {
    
//    private let router: WeakRouter<HomeRoute>?
    private let router: WeakRouter<MyYardRoute>?
    private let routerhomepay: WeakRouter<HomePayRoute>?
    private let routerweb: WeakRouter<HomeWebRoute>?
//    private let routerintercom: WeakRouter<IntercomWebRoute>?

    private let apiWrapper: APIWrapper
    private let permissionService: PermissionService
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService
    
    private let citiesList = BehaviorSubject<[APILocation]>(value: [])
    private let streetsList = BehaviorSubject<[APIStreet]>(value: [])
    private let buildingsList = BehaviorSubject<[String]>(value: [])
    
    private var loadedStreets = [String: [APIStreet]]()
    private var loadedBuildings = [String: [APIHouse]]()
    
    private let flatsList = BehaviorSubject<[String]>(value: [])
    
    private let activityTracker = ActivityTracker()
    private let errorTracker = ErrorTracker()
    
    init(
        routerweb: WeakRouter<HomeWebRoute>,
        apiWrapper: APIWrapper,
        permissionService: PermissionService,
        logoutHelper: LogoutHelper,
        alertService: AlertService
    ) {
        self.routerweb = routerweb
        self.router = nil
        self.routerhomepay = nil
        self.apiWrapper = apiWrapper
        self.permissionService = permissionService
        self.logoutHelper = logoutHelper
        self.alertService = alertService
    }
    
    init(
        routerhomepay: WeakRouter<HomePayRoute>,
        apiWrapper: APIWrapper,
        permissionService: PermissionService,
        logoutHelper: LogoutHelper,
        alertService: AlertService
    ) {
        self.routerhomepay = routerhomepay
        self.routerweb = nil
        self.router = nil
        self.apiWrapper = apiWrapper
        self.permissionService = permissionService
        self.logoutHelper = logoutHelper
        self.alertService = alertService
    }
    
    init(
        router: WeakRouter<MyYardRoute>,
        apiWrapper: APIWrapper,
        permissionService: PermissionService,
        logoutHelper: LogoutHelper,
        alertService: AlertService
    ) {
        self.router = router
        self.routerweb = nil
        self.routerhomepay = nil
        self.apiWrapper = apiWrapper
        self.permissionService = permissionService
        self.logoutHelper = logoutHelper
        self.alertService = alertService
    }
    
    func transform(input: Input) -> Output {
        errorTracker.asDriver()
            .catchAuthorizationError { [weak self] in
                guard let self = self else {
                    return
                }
                
                self.logoutHelper.showAuthErrorAlert(
                    activityTracker: self.activityTracker,
                    errorTracker: self.errorTracker,
                    disposeBag: self.disposeBag
                )
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] error in
                    let nsError = error as NSError
                    
                    // MARK: Если возвращается qrRegistrationError - это "не ошибка", поэтому показываем ее иначе
                    
                    if nsError.domain == NSError.APIWrapperError.domain, nsError.code == 3007 {
                        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                            if let router = self?.router {
                                router.trigger(.main)
                            } else if let router = self?.routerweb {
                                router.trigger(.main)
                            } else if let router = self?.routerhomepay {
                                router.trigger(.main)
                            } else {
                                return
                            }
                        }
                        
                        if let router = self?.router {
                            router.trigger(
                                .dialog(
                                    title: error.localizedDescription,
                                    message: nil,
                                    actions: [okAction]
                                )
                            )
                        } else if let router = self?.routerweb {
                            router.trigger(
                                .dialog(
                                    title: error.localizedDescription,
                                    message: nil,
                                    actions: [okAction]
                                )
                            )
                        } else if let router = self?.routerhomepay {
                            router.trigger(
                                .dialog(
                                    title: error.localizedDescription,
                                    message: nil,
                                    actions: [okAction]
                                )
                            )
                        }
                        
                        return
                    }
                    
                    if nsError == NSError.PermissionError.noCameraPermission {
                        let msg = "Чтобы использовать эту функцию, перейдите в настройки и предоставьте доступ к камере"
                        
                        self?.router?.trigger(.appSettings(title: "Нет доступа к камере", message: msg))
                        self?.routerweb?.trigger(.appSettings(title: "Нет доступа к камере", message: msg))
                        self?.routerhomepay?.trigger(.appSettings(title: "Нет доступа к камере", message: msg))

                        return
                    }
                    
                    self?.router?.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                    self?.routerweb?.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                    self?.routerhomepay?.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        apiWrapper.getAllLocations()
            .trackError(errorTracker)
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
                        .trackError(self.errorTracker)
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
                        .trackError(self.errorTracker)
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
            .flatMapLatest { [weak self] _ -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.permissionService.hasAccess(to: .video)
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    
//                    self.router?.trigger(.qrCodeScan(delegate: self))
                }
            )
            .disposed(by: disposeBag)
        
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router?.trigger(.back)
                    self?.routerweb?.trigger(.back)
                    self?.routerhomepay?.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        let isAbleToProceed = Driver
            .combineLatest(
                input.inputCityName,
                input.inputStreetName,
                input.inputBuildingName
            )
            .map { args -> Bool in
                let (cityName, streetName, buildingName) = args
                
                guard let uCityName = cityName?.trimmed, !uCityName.isEmpty,
                    let uStreetName = streetName?.trimmed, !uStreetName.isEmpty,
                    let uBuildingName = buildingName?.trimmed, !uBuildingName.isEmpty else {
                    return false
                }
                
                return true
            }
        
        let requestData = input.checkServicesTapped.withLatestFrom(
            Driver
                .combineLatest(
                    input.inputCityName,
                    input.inputStreetName,
                    input.inputBuildingName,
                    input.inputFlatName
                )
            )
            .flatMap { [weak self] args -> Driver<(String, String?, String?)> in
                let (cityName, streetName, buildingName, flatName) = args
                
                guard let self = self,
                    let uCityName = cityName?.trimmed, !uCityName.isEmpty,
                    let uStreetName = streetName?.trimmed, !uStreetName.isEmpty,
                    let uBuildingName = buildingName?.trimmed, !uBuildingName.isEmpty else {
                    return .empty()
                }
                
                var addressString = [uCityName, uStreetName, uBuildingName].joined(separator: ", ")
                
                if let uFlatName = flatName?.trimmed, !uFlatName.isEmpty {
                    addressString += ", квартира \(uFlatName)"
                }
                
                guard let buildings = self.loadedBuildings[uStreetName] else {
                    return .just((addressString, nil, nil))
                }
                
                let houseId = buildings.first { $0.number == uBuildingName }?.houseId
                
                guard let flat = flatName?.trimmed, !flat.isEmpty else {
                    return .just((addressString, houseId, nil))
                }
                return .just((addressString, houseId, flat))
            }
        
        let withoutHouseId = requestData.flatMap { args -> Driver<String> in
            let (address, houseId, flat) = args
            
            guard houseId == nil else {
                return .empty()
            }
            
            return .just(address)
        }
        
        withoutHouseId
            .drive(
                onNext: { [weak self] address in
                    self?.router?.trigger(.unavailableServices(address: address))
                    self?.routerweb?.trigger(.unavailableServices(address: address))
                    self?.routerhomepay?.trigger(.unavailableServices(address: address))
                }
            )
            .disposed(by: disposeBag)

        let withHouseId = requestData
            .flatMap { args -> Driver<(String, String, String?)> in
                let (address, houseId, flat) = args
                
                guard let uHouseId = houseId else {
                    return .empty()
                }
                
                guard let uFlat = flat else {
                    return .just((address, uHouseId, nil))
                }
                return .just((address, uHouseId, uFlat))
            }
        
        withHouseId
            .flatMapLatest { [weak self] args -> Driver<(String, String, String?)?> in
                guard let self = self else {
                    return .just(nil)
                }

                let (address, houseId, flat) = args

                return self.apiWrapper.checkOfferta(houseId: houseId, flat: flat)
                    .trackError(self.errorTracker)
                    .map {
                        guard let offers = $0 else {
                            return nil
                        }
                        guard offers.isEmpty else {
                            self.router?.trigger(.acceptOffertaByAddress(houseId: houseId, flat: flat, offers: offers))
                            self.routerweb?.trigger(.acceptOffertaByAddress(houseId: houseId, flat: flat, offers: offers))
                            self.routerhomepay?.trigger(.acceptOffertaByAddress(houseId: houseId, flat: flat, offers: offers))
                            return nil
                        }
                        return (address, houseId, flat)
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .flatMapLatest { [weak self] args -> Driver<(String, GetServicesResponseData?)?> in
                guard let self = self else {
                    return .just(nil)
                }

                let (address, houseId, flat) = args

                return self.apiWrapper.getServicesByHouseId(houseId: houseId, flat: flat)
                    .trackError(self.errorTracker)
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
                        self.router?.trigger(.unavailableServices(address: address))
                        self.routerweb?.trigger(.unavailableServices(address: address))
                        self.routerhomepay?.trigger(.unavailableServices(address: address))
                        return
                    }
                    if services.count == 1 {
                        let srv = services.filter {
                            return ($0.icon == "domophone") && $0.title.isEmpty
                        }
                        if !srv.isEmpty {
                            self.router?.trigger(.main)
                            self.routerweb?.trigger(.main)
                            self.routerhomepay?.trigger(.main)
                            NotificationCenter.default.post(name: .addressAdded, object: nil)
                            return
                        }
                    }
                    self.router?.trigger(.availableServices(address: address, services: services))
                    self.routerweb?.trigger(.availableServices(address: address, services: services))
                    self.routerhomepay?.trigger(.availableServices(address: address, services: services))
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            cities: citiesList.asDriver(onErrorJustReturn: [])
                .map { $0.map { $0.name } },
            streets: streetsList.asDriver(onErrorJustReturn: [])
                .map { $0.map { $0.name } },
            buildings: buildingsList.asDriver(onErrorJustReturn: []),
            flats: flatsList.asDriver(onErrorJustReturn: []),
            isAbleToProceed: isAbleToProceed
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
        let isAbleToProceed: Driver<Bool>
    }
    
}

extension InputAddressViewModel: QRCodeScanViewModelDelegate {
    
    // MARK: происходит глич анимации, если мы пытаемся презентануть ошибку до того, как завершился возврат назад
    // Он пытается презентнуть ошибку от того экрана, с которого мы возвращаемся
    // Поэтому было решено дергать back отсюда, ждать завершения транзишена, а потом уже делать запрос к API
    // Если ошибка и выскочит, то она презентнется нормально, поскольку мы уже ушли с того экрана
    
    func qrCodeScanViewModel(_ viewModel: QRCodeScanViewModel, didExtractCode code: String) {
        router?.rx
            .trigger(.back)
            .asDriverOnErrorJustComplete()
            .flatMapLatest { [weak self] _ -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper
                    .registerQR(qr: code)
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] _ in
                    NotificationCenter.default.post(name: .addressAdded, object: nil)
                    self?.apiWrapper.forceUpdateAddress = true
                    self?.apiWrapper.forceUpdateSettings = true
                    self?.apiWrapper.forceUpdatePayments = true
                    
                    self?.router?.trigger(.main)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
// swiftlint:enable type_body_length function_body_length cyclomatic_complexity file_length
