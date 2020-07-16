//
//  APITarget.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Moya

enum APITarget {
    
    case registerQR(request: RegisterQRRequest)
    case openDoor(request: OpenDoorRequest)
    case resetCode(request: ResetCodeRequest)
    case getAddressList(request: GetAddressListRequest)
    case intercom(request: IntercomRequest)
    case getSettingsList(request: GetSettingsListRequest)
    case access(request: AccessRequest)
    case resend(request: ResendRequest)
    case offices(request: OfficesRequest)
    
    case allCCTV(request: AllCCTVRequest)
    case recPrepare(request: RecPrepareRequest)
    case recDownload(request: RecDownloadRequest)
    case streamInfo(request: StreamInfoRequest)
    
    case getAddress(request: GetAddressRequest)
    case getGeoCoder(request: GeoCoderRequest)
    case getHouses(request: GetHousesRequest)
    case getServices(request: GetServicesRequest)
    case getAllLocations(request: GetAllLocationsRequest)
    case getStreets(request: GetStreetsRequest)
    
    case inbox(request: InboxRequest)
    case unreaded(request: UnreadedRequest)
    case delivered(request: DeliveredRequest)
    case chatReaded(request: ChatReadedRequest)
    
    case getListConnect(request: GetListConnectRequest)
    case createIssue(request: CreateIssueRequest)
    case actionIssue(request: ActionIssueRequest)
    case commentIssue(request: CommentIssueRequest)
    
    case addMyPhone(request: AddMyPhoneRequest)
    case requestCode(request: RequestCodeRequest)
    case registerPushToken(request: RegisterPushTokenRequest)
    case confirmCode(request: ConfirmCodeRequest)
    case getPaymentsList(request: GetPaymentsListRequest)
    case sendName(request: SendNameRequest)
    case restore(request: RestoreRequest)
    case notification(request: NotificationRequest)
    
    case payPrepare(request: PayPrepareRequest)
    case payProcess(request: PayProcessRequest)
    case sberbankPayProcess(request: SberbankPayProcessRequest)
    
}

extension APITarget: TargetType {
    
    var baseURL: URL {
        switch self {
        case .sberbankPayProcess:
            return URL(string: "https://securepayments.sberbank.ru/payment/applepay")!
            
        case .streamInfo(let request):
            return URL(string: request.cameraUrl)!
            
        default:
            return URL(string: "https://dm.lanta.me/api")!
        }
    }
    
    var path: String {
        switch self {
        case .registerQR: return "address/registerQR"
        case .intercom: return "address/intercom"
        case .openDoor: return "address/openDoor"
        case .resetCode: return "address/resetCode"
        case .getSettingsList: return "address/getSettingsList"
        case .getAddressList: return "address/getAddressList"
        case .access: return "address/access"
        case .resend: return "address/resend"
        case .offices: return "address/offices"
            
        case .allCCTV: return "cctv/all"
        case .recPrepare: return "cctv/recPrepare"
        case .recDownload: return "cctv/recDownload"
        case .streamInfo: return "recording_status.json"
            
        case .getAddress: return "geo/address"
        case .getGeoCoder: return "geo/coder"
        case .getHouses: return "geo/getHouses"
        case .getServices: return "geo/getServices"
        case .getAllLocations: return "geo/getAllLocations"
        case .getStreets: return "geo/getStreets"
            
        case .inbox: return "inbox/inbox"
        case .unreaded: return "inbox/unreaded"
        case .delivered: return "inbox/delivered"
        case .chatReaded: return "inbox/chatReaded"
            
        case .getListConnect: return "issues/listConnect"
        case .createIssue: return "issues/create"
        case .actionIssue: return "issues/action"
        case .commentIssue: return "issues/comment"
            
        case .addMyPhone: return "user/addMyPhone"
        case .requestCode: return "user/requestCode"
        case .registerPushToken: return "user/registerPushToken"
        case .confirmCode: return "user/confirmCode"
        case .getPaymentsList: return "user/getPaymentsList"
        case .sendName: return "user/sendName"
        case .restore: return "user/restore"
        case .notification: return "user/notification"
            
        case .payPrepare: return "pay/prepare"
        case .payProcess: return "pay/process"
        case .sberbankPayProcess: return "payment.do"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .streamInfo: return .get
        default: return .post
        }
    }
    
    var headers: [String: String]? {
        let defaultHeaders = [
            "Content-type": "application/json"
        ]
        
        // swiftlint:disable:next closure_body_length
        let authorization: String? = {
            switch self {
            case .registerQR(let request): return request.accessToken
            case .intercom(let request): return request.accessToken
            case .openDoor(let request): return request.accessToken
            case .resetCode(let request): return request.accessToken
            case .getSettingsList(let request): return request.accessToken
            case .getAddressList(let request): return request.accessToken
            case .access(let request): return request.accessToken
            case .resend(let request): return request.accessToken
            case .offices(let request): return request.accessToken
                
            case .allCCTV(let request): return request.accessToken
            case .recPrepare(let request): return request.accessToken
            case .recDownload(let request): return request.accessToken
                
            case .getAddress(let request): return request.accessToken
            case .getGeoCoder(let request): return request.accessToken
            case .getHouses(let request): return request.accessToken
            case .getServices(let request): return request.accessToken
            case .getAllLocations(let request): return request.accessToken
            case .getStreets(let request): return request.accessToken
                
            case .inbox(let request): return request.accessToken
            case .unreaded(let request): return request.accessToken
            case .delivered(let request): return request.accessToken
            case .chatReaded(let request): return request.accessToken
                
            case .getListConnect(let request): return request.accessToken
            case .createIssue(let request): return request.accessToken
            case .actionIssue(let request): return request.accessToken
            case .commentIssue(let request): return request.accessToken
                
            case .addMyPhone(let request): return request.accessToken
            case .registerPushToken(let request): return request.accessToken
            case .getPaymentsList(let request): return request.accessToken
            case .sendName(let request): return request.accessToken
            case .restore(let request): return request.accessToken
            case .notification(let request): return request.accessToken
                
            case .payPrepare(let request): return request.accessToken
            case .payProcess(let request): return request.accessToken
                
            default: return nil
            }
        }()
        
        guard let token = authorization else {
            return defaultHeaders
        }
        
        return defaultHeaders.merging(["Authorization": "Bearer " + token]) { _, new in new }
    }
    
    var task: Task {
        switch self {
        case .streamInfo: return .requestParameters(parameters: requestParameters, encoding: URLEncoding.default)
        default: return .requestParameters(parameters: requestParameters, encoding: JSONEncoding.default)
        }
    }
    
    var requestParameters: [String: Any] {
        switch self {
        case .registerQR(let request): return request.requestParameters
        case .intercom(let request): return request.requestParameters
        case .openDoor(let request): return request.requestParameters
        case .resetCode(let request): return request.requestParameters
        case .getSettingsList(let request): return request.requestParameters
        case .getAddressList(let request): return request.requestParameters
        case .access(let request): return request.requestParameters
        case .resend(let request): return request.requestParameters
        case .offices(let request): return request.requestParameters
            
        case .allCCTV(let request): return request.requestParameters
        case .recPrepare(let request): return request.requestParameters
        case .recDownload(let request): return request.requestParameters
        case .streamInfo(let request): return request.requestParameters
            
        case .getAddress(let request): return request.requestParameters
        case .getGeoCoder(let request): return request.requestParameters
        case .getHouses(let request): return request.requestParameters
        case .getServices(let request): return request.requestParameters
        case .getAllLocations(let request): return request.requestParameters
        case .getStreets(let request): return request.requestParameters
            
        case .inbox(let request): return request.requestParameters
        case .unreaded(let request): return request.requestParameters
        case .delivered(let request): return request.requestParameters
        case .chatReaded(let request): return request.requestParameters

        case .getListConnect(let request): return request.requestParameters
        case .createIssue(let request): return request.requestParameters
        case .actionIssue(let request): return request.requestParameters
        case .commentIssue(let request): return request.requestParameters
            
        case .addMyPhone(let request): return request.requestParameters
        case .requestCode(let request): return request.requestParameters
        case .registerPushToken(let request): return request.requestParameters
        case .confirmCode(let request): return request.requestParameters
        case .getPaymentsList(let request): return request.requestParameters
        case .sendName(let request): return request.requestParameters
        case .restore(let request): return request.requestParameters
        case .notification(let request): return request.requestParameters
            
        case .payPrepare(let request): return request.requestParameters
        case .payProcess(let request): return request.requestParameters
        case .sberbankPayProcess(let request): return request.requestParameters
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
}
