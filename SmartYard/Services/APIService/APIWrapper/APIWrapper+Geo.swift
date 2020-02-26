//
//  APIWrapper+Geo.swift
//  SmartYard
//
//  Created by Mad Brains on 26.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension APIWrapper {
    
    func getAddressByHouseId(houseId: String) -> Single<GetAddressResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetAddressRequest(accessToken: accessToken, houseId: houseId)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performGetAddressRequest(request) { result in
                switch result {
                case let .success(data): single(.success(data))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func getCoordinatesByAddress(address: String) -> Single<GeoCoderResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GeoCoderRequest(accessToken: accessToken, address: address)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performGetGeoCoderRequest(request) { result in
                switch result {
                case let .success(data): single(.success(data))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func getHousesByStreet(streetId: String) -> Single<GetHousesResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetHousesRequest(accessToken: accessToken, streetId: streetId)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performGetHousesRequest(request) { result in
                switch result {
                case let .success(data): single(.success(data))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func getServicesByHouseId(houseId: String) -> Single<GetServicesResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetServicesRequest(accessToken: accessToken, houseId: houseId)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performGetServicesRequest(request) { result in
                switch result {
                case let .success(data): single(.success(data))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func getAllLocations() -> Single<GetAllLocationsResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetAllLocationsRequest(accessToken: accessToken)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performGetAllLocationsRequest(request) { result in
                switch result {
                case let .success(data): single(.success(data))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func getStreetsByLocation(locationId: String) -> Single<GetStreetsResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetStreetsRequest(accessToken: accessToken, locationId: locationId)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performGetStreetsRequest(request) { result in
                switch result {
                case let .success(data): single(.success(data))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
}
