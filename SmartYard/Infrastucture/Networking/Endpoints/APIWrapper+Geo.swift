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
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetAddressRequest(accessToken: accessToken, houseId: houseId)
        
        return provider.rx
            .request(.getAddress(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsDefaultResponse()
    }
    
    func getCoordinatesByAddress(address: String) -> Single<GeoCoderResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GeoCoderRequest(accessToken: accessToken, address: address)
        
        return provider.rx
            .request(.getGeoCoder(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsDefaultResponse()
    }
    
    func getHousesByStreet(streetId: String) -> Single<GetHousesResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetHousesRequest(accessToken: accessToken, streetId: streetId)
        
        return provider.rx
            .request(.getHouses(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
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
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func getAllLocations() -> Single<GetAllLocationsResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetAllLocationsRequest(accessToken: accessToken)
        
        return provider.rx
            .request(.getAllLocations(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func getStreetsByLocation(locationId: String) -> Single<GetStreetsResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetStreetsRequest(accessToken: accessToken, locationId: locationId)
        
        return provider.rx
            .request(.getStreets(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
}
