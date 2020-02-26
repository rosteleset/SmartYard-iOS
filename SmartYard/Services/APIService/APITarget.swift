//
//  APITarget.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Moya

enum APITarget {
    
    case openDoor(request: OpenDoorRequest)
    case resetCode(request: ResetCodeRequest)
    case getAddressList(request: GetAddressListRequest)
    case grantHourGuestAccess(request: IntercomRequest)
    case getSettingsList(request: GetSettingsListRequest)
    
    case addMyPhone(request: AddMyPhoneRequest)
    case requestCode(request: RequestCodeRequest)
    case registerPushToken(request: RegisterPushTokenRequest)
    case confirmCode(request: ConfirmCodeRequest)
    case getPaymentsList(request: GetPaymentsListRequest)
    case sendName(request: SendNameRequest)
    
    case getAddress(request: GetAddressRequest)
    case getGeoCoder(request: GeoCoderRequest)
    case getHouses(request: GetHousesRequest)
    case getServices(request: GetServicesRequest)
    case getAllLocations(request: GetAllLocationsRequest)
}

extension APITarget: TargetType {
    
    var baseURL: URL {
        return URL(string: "https://dm.lanta.me/api")!
    }
    
    var path: String {
        switch self {
        case .grantHourGuestAccess: return "address/intercom"
        case .openDoor: return "address/openDoor"
        case .resetCode: return "address/resetCode"
        case .getSettingsList: return "address/getSettingsList"
        case .getAddressList: return "address/getAddressList"
            
        case .addMyPhone: return "user/addMyPhone"
        case .requestCode: return "user/requestCode"
        case .registerPushToken: return "user/registerPushToken"
        case .confirmCode: return "user/confirmCode"
        case .getPaymentsList: return "user/getPaymentsList"
        case .sendName: return "user/sendName"
            
        case .getAddress: return "geo/address"
        case .getGeoCoder: return "geo/coder"
        case .getHouses: return "geo/getHouses"
        case .getServices: return "geo/getServices"
        case .getAllLocations: return "geo/getAllLocations"
        }
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var headers: [String: String]? {
        let defaultHeaders = [
            "Content-type": "application/json"
        ]
        
        let authorization: String? = {
            switch self {
            case .grantHourGuestAccess(let request): return request.accessToken
            case .openDoor(let request): return request.accessToken
            case .resetCode(let request): return request.accessToken
            case .getSettingsList(let request): return request.accessToken
            case .getAddressList(let request): return request.accessToken
                
            case .addMyPhone(let request): return request.accessToken
            case .registerPushToken(let request): return request.accessToken
            case .getPaymentsList(let request): return request.accessToken
            case .sendName(let request): return request.accessToken
                
            case .getAddress(let request): return request.accessToken
            case .getGeoCoder(let request): return request.accessToken
            case .getHouses(let request): return request.accessToken
            case .getServices(let request): return request.accessToken
            case .getAllLocations(let request): return request.accessToken
                
            default: return nil
            }
        }()
        
        guard let token = authorization else {
            return defaultHeaders
        }
        
        return defaultHeaders.merging(["Authorization": "Bearer " + token]) { _, new in new }
    }
    
    var task: Task {
        return .requestParameters(parameters: requestParameters, encoding: JSONEncoding.default)
    }
    
    var requestParameters: [String: Any] {
        switch self {
        case .grantHourGuestAccess(let request): return request.requestParameters
        case .openDoor(let request): return request.requestParameters
        case .resetCode(let request): return request.requestParameters
        case .getSettingsList(let request): return request.requestParameters
        case .getAddressList(let request): return request.requestParameters

        case .addMyPhone(let request): return request.requestParameters
        case .requestCode(let request): return request.requestParameters
        case .registerPushToken(let request): return request.requestParameters
        case .confirmCode(let request): return request.requestParameters
        case .getPaymentsList(let request): return request.requestParameters
        case .sendName(let request): return request.requestParameters
            
        case .getAddress(let request): return request.requestParameters
        case .getGeoCoder(let request): return request.requestParameters
        case .getHouses(let request): return request.requestParameters
        case .getServices(let request): return request.requestParameters
        case .getAllLocations(let request): return request.requestParameters
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
}
