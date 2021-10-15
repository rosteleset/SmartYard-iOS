//
//  APIWrapper+Geo.swift
//  SmartYard
//
//  Created by Mad Brains on 26.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension APIWrapper {
    
    func getAddressByHouseId(houseId: String) -> Single<GetAddressResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetAddressRequest(accessToken: accessToken, houseId: houseId)
        
        return provider.rx
            .request(.getAddress(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
    func getCoordinatesByAddress(address: String) -> Single<GeoCoderResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GeoCoderRequest(accessToken: accessToken, address: address)
        
        return provider.rx
            .request(.getGeoCoder(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
    func getHousesByStreet(streetId: String) -> Single<GetHousesResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetHousesRequest(accessToken: accessToken, streetId: streetId)
        
        return provider.rx
            .request(.getHouses(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func getServicesByHouseId(houseId: String?) -> Single<GetServicesResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        guard let houseId = houseId else {
            return .error(NSError.APIWrapperError.houseIdMissingError)
        }
        
        let request = GetServicesRequest(accessToken: accessToken, houseId: houseId)
        
        return provider.rx
            .request(.getServices(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func getAllLocations() -> Single<GetAllLocationsResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetAllLocationsRequest(accessToken: accessToken)
        
        return provider.rx
            .request(.getAllLocations(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func getStreetsByLocation(locationId: String) -> Single<GetStreetsResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetStreetsRequest(accessToken: accessToken, locationId: locationId)
        
        return provider.rx
            .request(.getStreets(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
}
