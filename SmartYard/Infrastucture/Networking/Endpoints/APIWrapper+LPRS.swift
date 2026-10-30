//
//  APIWrapper+LPRS.swift
//  SmartYard
//
//  Created by Александр Попов on 09.06.2025.
//  Copyright © 2025 Sesameware. All rights reserved.
//

import RxSwift
import Foundation

extension APIWrapper {
    
    func getLicensePlates(forFlatId flatId: Int) -> Single<GetLicensePlatesResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetLicensePlatesRequest(
            accessToken: accessToken,
            flatId: flatId
        )
        Logger.logDebug("Request data: \(String(describing: request))")

        return provider.rx
            .request(.getLicensePlates(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func addLicensePlate(
        withNumber number: String, forFlatId flatId: Int,
        countryCode: String? = nil, validity: LicensePlateValidity = .unlimited
    ) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = AddLicensePlateRequest(
            accessToken: accessToken,
            flatId: flatId,
            number: number, countryCode: countryCode, validity: validity
        )
        Logger.logDebug("Request data: \(String(describing: request))")
        
        return provider.rx
            .request(.addLicensePlate(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func removeLicensePlate(withNumber number: String, forFlatId flatId: Int) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = RemoveLicensePlateRequest(
            accessToken: accessToken,
            flatId: flatId,
            number: number
        )
        Logger.logDebug("Request data: \(String(describing: request))")
        
        return provider.rx
            .request(.removeLicensePlate(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsVoidResponse()
            .mapToOptional()
    }
    

    func getLicensePlateFormats() -> Single<[APILicensePlateFormat]> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        let request = GetLicensePlateFormatsRequest(accessToken: accessToken)
        return provider.rx.request(.getLicensePlateFormats(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsEmptyDataInitializableResponse()
    }

    func getAllowedCars(forFlatId flatId: Int) -> Single<[AllowedCar]> {
        guard accessService.lprsVersion == .timed else {
            return getLicensePlates(forFlatId: flatId).map { numbers in
                (numbers ?? []).map { AllowedCar(rawNumber: $0) }
            }
        }
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        let request = GetLicensePlatesRequest(accessToken: accessToken, flatId: flatId)
        let plates: Single<[APILicensePlate]> = provider.rx
            .request(.getLicensePlatesV2(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsEmptyDataInitializableResponse()
        let ownWatchers: Single<[APITrackedEvent]> = accessService.eventsTrackingEnabled
            ? getTrackedEvents(flatId: flatId).map { $0 ?? [] } : .just([])
        return Single.zip(plates, ownWatchers).map { plates, watchers in
            var identities: Set<String> = []
            return plates.compactMap { plate in
                // listNumbersV2 may join watchers belonging to other devices. Only our own
                // getTrackedEvents response can establish this device's subscription state.
                let watcher = watchers.first {
                    $0.flatId == flatId && $0.eventType == 9
                        && $0.normalizedEventDetail.standardizedCarNumber == plate.plateNumber.standardizedCarNumber
                }
                let car = AllowedCar(
                    rawNumber: plate.plateNumber, countryCode: plate.countryCode,
                    validFrom: plate.validity.validFrom, validTo: plate.validity.validTo,
                    watcherId: watcher?.watcherId
                )
                return identities.insert(car.identity).inserted ? car : nil
            }
        }
    }

    func removeAllowedCar(_ car: AllowedCar, forFlatId flatId: Int) -> Single<Void?> {
        // The current removeNumber contract validates Russian numbers and does not accept
        // a country code. Never claim a foreign pass was deleted by deleting a different key.
        guard car.countryCode == "ru" else {
            return .error(LicensePlateAccessError.unsupportedCountryRemoval)
        }
        return removeLicensePlate(withNumber: car.apiNumber, forFlatId: flatId)
    }

    func saveAllowedCar(
        _ car: AllowedCar, trackingEnabled: Bool, replacing original: AllowedCar?, flatId: Int
    ) -> Single<LicensePlateSaveResult> {
        guard car.validity.isValid else { return .error(LicensePlateAccessError.invalidPeriod) }
        let isTimed = accessService.lprsVersion == .timed
        return Single.deferred { [self] in
            var result = LicensePlateSaveResult(
                car: car.withWatcher(original?.identity == car.identity ? original?.watcherId : nil)
            )
            return addLicensePlate(
                withNumber: car.apiNumber, forFlatId: flatId,
                countryCode: isTimed ? car.countryCode : nil,
                validity: isTimed ? car.validity : .unlimited
            )
            .flatMap { _ -> Single<Void> in
                guard let original, original.identity != car.identity else { return .just(()) }
                // The same number is updated in place by addNumber. For a rename, create
                // the new pass first so a failed addition cannot destroy the existing pass.
                return self.removeAllowedCar(original, forFlatId: flatId)
                    .map { _ in result.removedOriginal = true }
                    .catch { _ in
                        result.issues.append(.originalAccess)
                        return .just(())
                    }
            }
            .flatMap { _ -> Single<Void> in
                guard isTimed, self.accessService.eventsTrackingEnabled else { return .just(()) }
                return self.synchronizeLicensePlateTracking(
                    number: car.apiNumber, enabled: trackingEnabled, flatId: flatId
                )
                .flatMap { watcherId -> Single<Void> in
                    result.car = car.withWatcher(watcherId)
                    guard result.removedOriginal, let original, original.apiNumber != car.apiNumber else {
                        return .just(())
                    }
                    return self.synchronizeLicensePlateTracking(
                        number: original.apiNumber, enabled: false, flatId: flatId
                    ).map { _ in () }
                }
                .catch { _ in
                    result.issues.append(.tracking)
                    return .just(())
                }
            }
            .flatMap { _ in
                self.getAllowedCars(forFlatId: flatId)
                    .map { cars in
                        result.cars = cars
                        result.car = cars.first { $0.identity == car.identity } ?? result.car
                        return result
                    }
                    .catch { _ in
                        result.issues.append(.refresh)
                        return .just(result)
                    }
            }
        }
    }

    private func synchronizeLicensePlateTracking(
        number: String, enabled: Bool, flatId: Int
    ) -> Single<Int?> {
        getTrackedEvents(flatId: flatId).flatMap { [self] events -> Single<Int?> in
            let matching = (events ?? []).filter {
                $0.flatId == flatId && $0.eventType == 9
                    && $0.normalizedEventDetail.standardizedCarNumber == number
            }
            if enabled {
                if let watcherId = matching.first?.watcherId { return .just(watcherId) }
                return trackEvent(flatId: flatId, eventType: 9, eventDetail: number, comments: "")
                    .flatMap { response -> Single<Int?> in
                        guard let id = response?.watcherId, id > 0 else {
                            return .error(NSError.APIWrapperError.noDataError)
                        }
                        return .just(id)
                    }
            }
            return Observable.from(matching.map(\.watcherId))
                .concatMap { self.untrackEvent(watcherId: $0).asObservable() }
                .toArray()
                .map { _ in nil }
        }
    }

}
