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
        
        return provider.rx
            .request(.getAddress(request: request))
            .filterSuccessfulCodes()
            .map(BaseAPIResponse<GetAddressResponseData>.self)
            .flatMap { response in
                guard let data = response.data else {
                    return .error(NSError.APIWrapperError.noDataError)
                }
                
                return .just(data)
            }
    }
    
    func getCoordinatesByAddress(address: String) -> Single<GeoCoderResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GeoCoderRequest(accessToken: accessToken, address: address)
        
        return provider.rx
            .request(.getGeoCoder(request: request))
            .filterSuccessfulCodes()
            .map(BaseAPIResponse<GeoCoderResponseData>.self)
            .flatMap { response in
                guard let data = response.data else {
                    return .error(NSError.APIWrapperError.noDataError)
                }
                
                return .just(data)
            }
    }
    
    func getHousesByStreet(streetId: String) -> Single<GetHousesResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetHousesRequest(accessToken: accessToken, streetId: streetId)
        
        return provider.rx
            .request(.getHouses(request: request))
            .filterSuccessfulCodes()
            .map(BaseAPIResponse<GetHousesResponseData>.self)
            .flatMap { response in
                if let data = response.data {
                    return .just(data)
                } else if response.code == 204 {
                    return .just([])
                } else {
                    return .error(NSError.APIWrapperError.noDataError)
                }
            }
    }
    
    func getServicesByHouseId(houseId: String?) -> Single<GetServicesResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        guard let houseId = houseId else {
            return .error(NSError.APIWrapperError.houseIdMissingError)
        }
        
        let request = GetServicesRequest(accessToken: accessToken, houseId: houseId)
        
        return provider.rx
            .request(.getServices(request: request))
            .filterSuccessfulCodes()
            .map(BaseAPIResponse<GetServicesResponseData>.self)
            .flatMap { response in
                if let data = response.data {
                    return .just(data)
                } else if response.code == 204 {
                    return .just([])
                } else {
                    return .error(NSError.APIWrapperError.noDataError)
                }
            }
    }
    
    func getAllLocations() -> Single<GetAllLocationsResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetAllLocationsRequest(accessToken: accessToken)
        
        return provider.rx
            .request(.getAllLocations(request: request))
            .filterSuccessfulCodes()
            .map(BaseAPIResponse<GetAllLocationsResponseData>.self)
            .flatMap { response in
                if let data = response.data {
                    return .just(data)
                } else if response.code == 204 {
                    return .just([])
                } else {
                    return .error(NSError.APIWrapperError.noDataError)
                }
            }
    }
    
    func getStreetsByLocation(locationId: String) -> Single<GetStreetsResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetStreetsRequest(accessToken: accessToken, locationId: locationId)
        
        return provider.rx
            .request(.getStreets(request: request))
            .filterSuccessfulCodes()
            .map(BaseAPIResponse<GetStreetsResponseData>.self)
            .flatMap { response in
                if let data = response.data {
                    return .just(data)
                } else if response.code == 204 {
                    return .just([])
                } else {
                    return .error(NSError.APIWrapperError.noDataError)
                }
            }
    }
    
}
