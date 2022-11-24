//
//  APITarget.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Moya

enum APITarget {
    case getProvidersList
    case registerQR(request: RegisterQRRequest)
    case openDoor(request: OpenDoorRequest)
    case resetCode(request: ResetCodeRequest)
    case getAddressList(request: GetAddressListRequest)
    case intercom(request: IntercomRequest)
    case getSettingsList(request: GetSettingsListRequest)
    case access(request: AccessRequest)
    case resend(request: ResendRequest)
    case offices(request: OfficesRequest)
    case plog(request: PlogRequest)
    case plogDays(request: PlogDaysRequest)
    
    case allCCTV(request: AllCCTVRequest)
    case overviewCCTV(request: OverviewCCTVRequest)
    case youtube(request: YouTubeRequest)
    case recPrepare(request: RecPrepareRequest)
    case recDownload(request: RecDownloadRequest)
    case streamInfo(request: StreamInfoRequest)
    case getCamMap(request: CamMapCCTVRequest)
    case ranges(request: RangesRequest)
    
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
    
    case appVersion(request: AppVersionRequest)
    case addMyPhone(request: AddMyPhoneRequest)
    case requestCode(request: RequestCodeRequest)
    case registerPushToken(request: RegisterPushTokenRequest)
    case confirmCode(request: ConfirmCodeRequest)
    case checkPhone(request: CheckPhoneRequest)
    
    case getPaymentsList(request: GetPaymentsListRequest)
    case sendName(request: SendNameRequest)
    case restore(request: RestoreRequest)
    case notification(request: NotificationRequest)
    
    case extList(request: GetExtensionsListRequest)
    case ext(request: GetExtensionRequest)
    case options(request: GetOptionsRequest)

    case payPrepare(request: PayPrepareRequest)
    case payProcess(request: PayProcessRequest)
    case sberbankPayProcess(request: SberbankPayProcessRequest)
    case sberbankRegister(request: SberbankRegisterRequest)
    
    case getPersonFaces(request: GetPersonFacesRequest)
    case removePersonFace(request: RemovePersonFaceRequest)
    case likePersonFace(request: LikePersonFaceRequest)
    case disLikePersonFace(request: DisLikePersonFaceRequest)
}

extension APITarget: TargetType {
    
    var baseURL: URL {
        switch self {
        case .getProvidersList:
            return URL(string: Constants.provListURL + "?_=\(Int.random(in: 0..<Int.max))")!
        case .sberbankPayProcess:
            return URL(string: "https://securepayments.sberbank.ru/payment/applepay")!
        
        case .sberbankRegister:
            return URL(string: "https://securepayments.sberbank.ru/payment/rest")!
            
        case .streamInfo(let request):
            return URL(string: request.cameraUrl)!
            
        default:
            return URL(string: AccessService().backendURL)!
        }
    }
    
    var path: String {
        switch self {
        case .getProvidersList: return ""
        case .registerQR: return "address/registerQR"
        case .intercom: return "address/intercom"
        case .openDoor: return "address/openDoor"
        case .resetCode: return "address/resetCode"
        case .getSettingsList: return "address/getSettingsList"
        case .getAddressList: return "address/getAddressList"
        case .access: return "address/access"
        case .resend: return "address/resend"
        case .offices: return "address/offices"
        case .plog: return "address/plog"
        case .plogDays: return "address/plogDays"
        
        case .allCCTV: return "cctv/all"
        case .overviewCCTV: return "cctv/overview"
        case .youtube: return "cctv/youtube"
        case .recPrepare: return "cctv/recPrepare"
        case .recDownload: return "cctv/recDownload"
        case .getCamMap: return "cctv/camMap"
        case .streamInfo: return "recording_status.json"
        case .ranges: return "cctv/ranges"
            
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
            
        case .appVersion: return "user/appVersion"
        case .addMyPhone: return "user/addMyPhone"
        case .requestCode: return "user/requestCode"
        case .registerPushToken: return "user/registerPushToken"
        case .confirmCode: return "user/confirmCode"
        case .checkPhone: return "user/checkPhone"
        
        case .getPaymentsList: return "user/getPaymentsList"
        case .sendName: return "user/sendName"
        case .restore: return "user/restore"
        case .notification: return "user/notification"
            
        case .payPrepare: return "pay/prepare"
        case .payProcess: return "pay/process"
        case .sberbankPayProcess: return "payment.do"
        case .sberbankRegister: return "register.do"
            
        case .getPersonFaces: return "frs/listFaces"
        case .disLikePersonFace: return "frs/disLike"
        case .likePersonFace: return "frs/like"
        case .removePersonFace: return "frs/disLike"
        case .extList: return "ext/list"
        case .ext: return "ext/ext"
        case .options: return "ext/options"
        
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .streamInfo, .getProvidersList: return .get
        default: return .post
        }
    }
    
    var headers: [String: String]? {
        let defaultHeaders = [
            "Content-type": "application/json"
        ]
        
        // swiftlint:disable:next closure_body_length
        let (authorization, forceRefresh): (String?, Bool) = {
            switch self {
            case .registerQR(let request): return (request.accessToken, false)
            case .intercom(let request): return (request.accessToken, request.forceRefresh)
            case .openDoor(let request): return (request.accessToken, false)
            case .resetCode(let request): return (request.accessToken, false)
            case .getSettingsList(let request): return (request.accessToken, request.forceRefresh)
            case .getAddressList(let request): return (request.accessToken, request.forceRefresh)
            case .access(let request): return (request.accessToken, false)
            case .resend(let request): return (request.accessToken, false)
            case .offices(let request): return (request.accessToken, false)
            case .plog(let request): return (request.accessToken, request.forceRefresh)
            case .plogDays(let request): return (request.accessToken, request.forceRefresh)
            
            case .allCCTV(let request): return (request.accessToken, request.forceRefresh)
            case .overviewCCTV(let request): return (request.accessToken, request.forceRefresh)
            case .youtube(let request): return (request.accessToken, request.forceRefresh)
            case .recPrepare(let request): return (request.accessToken, false)
            case .recDownload(let request): return (request.accessToken, false)
            case .getCamMap(let request): return (request.accessToken, false)
            case .ranges(let request): return (request.accessToken, false)
            
            case .getAddress(let request): return (request.accessToken, false)
            case .getGeoCoder(let request): return (request.accessToken, false)
            case .getHouses(let request): return (request.accessToken, false)
            case .getServices(let request): return (request.accessToken, false)
            case .getAllLocations(let request): return (request.accessToken, false)
            case .getStreets(let request): return (request.accessToken, false)
                
            case .inbox(let request): return (request.accessToken, false)
            case .unreaded(let request): return (request.accessToken, false)
            case .delivered(let request): return (request.accessToken, false)
            case .chatReaded(let request): return (request.accessToken, false)
                
            case .getListConnect(let request): return (request.accessToken, request.forceRefresh)
            case .createIssue(let request): return (request.accessToken, false)
            case .actionIssue(let request): return (request.accessToken, false)
            case .commentIssue(let request): return (request.accessToken, false)
                
            case .appVersion(let request): return (request.accessToken, false)
            case .addMyPhone(let request): return (request.accessToken, false)
            case .registerPushToken(let request): return (request.accessToken, false)
            case .getPaymentsList(let request): return (request.accessToken, request.forceRefresh)
            case .sendName(let request): return (request.accessToken, false)
            case .restore(let request): return (request.accessToken, false)
            case .notification(let request): return (request.accessToken, false)
                
            case .payPrepare(let request): return (request.accessToken, false)
            case .payProcess(let request): return (request.accessToken, false)
                
            case .getPersonFaces(let request): return (request.accessToken, request.forceRefresh)
            case .removePersonFace(let request): return (request.accessToken, false)
            case .likePersonFace(let request): return (request.accessToken, false)
            case .disLikePersonFace(let request): return (request.accessToken, false)
                
            case .extList(let request): return (request.accessToken, false)
            case .ext(let request): return (request.accessToken, false)
            case .options(let request): return (request.accessToken, false)
            
            default: return (nil, false)
            }
        }()
        
        var additionalHeaders: [String: String] = [:]
        
        if let token = authorization {
            additionalHeaders.merge(["Authorization": "Bearer " + token]) { _, new in new }
        }
        
        if forceRefresh {
            additionalHeaders.merge(["X-Dm-Api-Refresh": " "]) { _, new in new }
        }
        
        switch self {
        case .sberbankRegister, .getProvidersList: return [:]
        default: return defaultHeaders.merging(additionalHeaders) { _, new in new }
        }
    }
    
    var task: Task {
        switch self {
        case .streamInfo, .sberbankRegister, .getProvidersList:
            return .requestParameters(parameters: requestParameters, encoding: URLEncoding.default)
        default:
            return .requestParameters(parameters: requestParameters, encoding: JSONEncoding.default)
        }
    }
    
    var requestParameters: [String: Any] {
        switch self {
        case .getProvidersList: return [:]
        case .registerQR(let request): return request.requestParameters
        case .intercom(let request): return request.requestParameters
        case .openDoor(let request): return request.requestParameters
        case .resetCode(let request): return request.requestParameters
        case .getSettingsList(let request): return request.requestParameters
        case .getAddressList(let request): return request.requestParameters
        case .access(let request): return request.requestParameters
        case .resend(let request): return request.requestParameters
        case .offices(let request): return request.requestParameters
        case .plog(let request): return request.requestParameters
        case .plogDays(let request): return request.requestParameters
        
        case .allCCTV(let request): return request.requestParameters
        case .overviewCCTV(let request): return request.requestParameters
        case .youtube(let request): return request.requestParameters
        case .recPrepare(let request): return request.requestParameters
        case .recDownload(let request): return request.requestParameters
        case .getCamMap(let request): return request.requestParameters
        case .streamInfo(let request): return request.requestParameters
        case .ranges(let request): return request.requestParameters
            
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
            
        case .appVersion(let request): return request.requestParameters
        case .addMyPhone(let request): return request.requestParameters
        case .requestCode(let request): return request.requestParameters
        case .registerPushToken(let request): return request.requestParameters
        case .confirmCode(let request): return request.requestParameters
        case .checkPhone(let request): return request.requestParameters
        
        case .getPaymentsList(let request): return request.requestParameters
        case .sendName(let request): return request.requestParameters
        case .restore(let request): return request.requestParameters
        case .notification(let request): return request.requestParameters
            
        case .payPrepare(let request): return request.requestParameters
        case .payProcess(let request): return request.requestParameters
        case .sberbankPayProcess(let request): return request.requestParameters
        case .sberbankRegister(let request): return request.requestParameters
        
        case .getPersonFaces(let request): return request.requestParameters
        case .removePersonFace(let request): return request.requestParameters
        case .likePersonFace(let request): return request.requestParameters
        case .disLikePersonFace(let request): return request.requestParameters
        
        case .extList(let request): return request.requestParameters
        case .ext(let request): return request.requestParameters
        case .options(let request): return request.requestParameters
        
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
}
