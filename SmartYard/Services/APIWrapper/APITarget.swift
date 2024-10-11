//
//  APITarget.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable closure_body_length

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
    case plog(request: PlogRequest)
    case plogDays(request: PlogDaysRequest)
    case shareGenerate(request: ShareGenerateRequest)
    case getContracts(request: GetContractsRequest)
    case setParentControl(request: SetParentControlRequest)
    
    case allCCTV(request: AllCCTVRequest)
    case camCCTV(request: CamCCTVRequest)
    case cityCoordinate(request: CityCoordinateRequest)
    case overviewCCTV(request: OverviewCCTVRequest)
    case youtube(request: YouTubeRequest)
    case recPrepare(request: RecPrepareRequest)
    case recSize(request: RecSizeRequest)
    case recDownload(request: RecDownloadRequest)
    case streamInfo(request: StreamInfoRequest)
    case getCamMap(request: CamMapCCTVRequest)
    case camSortCCTV(request: CamSortCCTVRequest)
    case allPlaces(request: AllPlacesRequest)
    case allCameras(request: AllCamerasRequest)
    
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

    case chatwootinbox(request: ChatwootGetMessagesRequest)
    case chatwootsend(request: ChatwootSendMessageRequest)
    case chatwootsendimage(request: ChatwootSendImageRequest)
    case chatwootlist(request: ChatwootGetChatListRequest)

    case getListConnect(request: GetListConnectRequest)
    case createIssue(request: CreateIssueRequest)
    case actionIssue(request: ActionIssueRequest)
    case commentIssue(request: CommentIssueRequest)
    
    case appVersion(request: AppVersionRequest)
    case appLogout(request: AppLogoutRequest)
    case addMyPhone(request: AddMyPhoneRequest)
    case requestCode(request: RequestCodeRequest)
    case registerPushToken(request: RegisterPushTokenRequest)
    case confirmCode(request: ConfirmCodeRequest)
    case checkPhone(request: CheckPhoneRequest)
    case acceptOfferta(request: AcceptOffertaRequest)
    case checkOfferta(request: CheckOffertaRequest)

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
    
    case payBalanceDetail(request: DetailRequest)
    case paySendDetail(request: SendDetailRequest)
    case payGetCards(request: GetCardsRequest)
    case payAuto(request: AutoPayRequest)
    case payNew(request: NewPayRequest)
    case payCheck(request: CheckPayRequest)
    case payRemoveCard(request: RemoveCardRequest)
    case addAutopay(request: AddAutopayRequest)
    case removeAutopay(request: RemoveAutopayRequest)
    case newSBPPay(request: CreateSBPOrderRequest)
    case updateSBPPay(request: UpdateSBPOrderRequest)
    case yooKassaNewPay(request: YooKassaNewPayRequest)
    
    case activateLimit(request: ActivateLimitRequest)
}

extension APITarget: TargetType {
    
    var baseURL: URL {
        switch self {
        case .sberbankPayProcess:
            return URL(string: "https://securepayments.sberbank.ru/payment/applepay")!
        
        case .sberbankRegister:
//            return URL(string: "https://securepayments.sberbank.ru/payment/rest")!
            return URL(string: "https://intercom-mobile-api.mycentra.ru/api/pay")!
            
        case .streamInfo(let request):
            return URL(string: request.cameraUrl)!
            
        default:
            return URL(string: AccessService().backendURL + "/api")!
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
        case .plog: return "address/plog"
        case .plogDays: return "address/plogDays"
        case .shareGenerate: return "address/intercom/url/v2/generate"
        case .getContracts: return "address/getContracts"
        case .setParentControl: return "contract/setParentControl"
        
        case .allCCTV: return "cctv/all"
        case .camCCTV: return "cctv/getCamById"
        case .cityCoordinate: return "cctv/cityCoordinate"
        case .overviewCCTV: return "cctv/overview"
        case .youtube: return "cctv/youtube"
        case .recPrepare: return "cctv/recPrepare"
        case .recSize: return "cctv/getArchiveSize"
        case .recDownload: return "cctv/recDownload"
        case .getCamMap: return "cctv/camMap"
        case .streamInfo: return "recording_status.json"
        case .camSortCCTV: return "cctv/sort"
        case .allPlaces: return "cctv/places"
        case .allCameras: return "cctv/cameras"
            
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
            
        case .chatwootinbox: return "inbox/message"
        case .chatwootsend: return "inbox/message"
        case .chatwootsendimage: return "inbox/message"
        case .chatwootlist: return "inbox/chat/all"
            
        case .getListConnect: return "issues/listConnect"
        case .createIssue: return "issues/create"
        case .actionIssue: return "issues/action"
        case .commentIssue: return "issues/comment"
            
        case .appVersion: return "user/appVersion"
        case .appLogout: return "user/logout"
        case .addMyPhone: return "user/addMyPhone"
        case .requestCode: return "user/requestCode"
        case .registerPushToken: return "user/registerPushToken"
        case .confirmCode: return "user/confirmCode"
        case .checkPhone: return "user/checkPhone"
        case .acceptOfferta: return "user/acceptOffer"
        case .checkOfferta: return "user/checkOffer"
        
        case .getPaymentsList: return "user/getPaymentsList"
        case .sendName: return "user/sendName"
        case .restore: return "user/restore"
        case .notification: return "user/notification"
            
        case .payPrepare: return "pay/prepare"
        case .payProcess: return "pay/process"
        case .sberbankPayProcess: return "payment.do"
//        case .sberbankRegister: return "register.do"
        case .sberbankRegister: return "fakeOrder"
            
        case .getPersonFaces: return "frs/listFaces"
        case .disLikePersonFace: return "frs/disLike"
        case .likePersonFace: return "frs/like"
        case .removePersonFace: return "frs/disLike"
        case .extList: return "ext/list"
        case .ext: return "ext/ext"
        case .options: return "ext/options"
            
        case .payBalanceDetail: return "pay/balance/detail"
        case .paySendDetail: return "pay/send/detail"
        case .payGetCards: return "pay/getCards"
        case .payAuto: return "pay/auto"
        case .payNew: return "pay/new"
        case .payCheck: return "pay/check"
        case .payRemoveCard: return "pay/removeCard"
        case .addAutopay: return "pay/addAuto"
        case .removeAutopay: return "pay/removeAuto"
        case .newSBPPay: return "pay/newFake"
        case .updateSBPPay: return "pay/checkFake"
        case .yooKassaNewPay: return "pay/mobile"

        case .activateLimit: return "contract/activateLimit"
            
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
        
        let (authorization, forceRefresh): (String?, Bool) = {
            switch self {
            case .registerQR(let request): return (request.accessToken, false)
            case .openDoor(let request): return (request.accessToken, false)
            case .resetCode(let request): return (request.accessToken, false)
            case .getAddressList(let request): return (request.accessToken, request.forceRefresh)
            case .intercom(let request): return (request.accessToken, request.forceRefresh)
            case .getSettingsList(let request): return (request.accessToken, request.forceRefresh)
            case .access(let request): return (request.accessToken, false)
            case .resend(let request): return (request.accessToken, false)
            case .offices(let request): return (request.accessToken, false)
            case .plog(let request): return (request.accessToken, request.forceRefresh)
            case .plogDays(let request): return (request.accessToken, request.forceRefresh)
            case .shareGenerate(let request): return (request.accessToken, false)
            case .getContracts(let request): return (request.accessToken, request.forceRefresh)
            case .setParentControl(let request): return (request.accessToken, false)
            
            case .allCCTV(let request): return (request.accessToken, request.forceRefresh)
            case .camCCTV(let request): return (request.accessToken, request.forceRefresh)
            case .cityCoordinate(let request): return (request.accessToken, request.forceRefresh)
            case .overviewCCTV(let request): return (request.accessToken, request.forceRefresh)
            case .youtube(let request): return (request.accessToken, request.forceRefresh)
            case .recPrepare(let request): return (request.accessToken, false)
            case .recSize(let request): return (request.accessToken, false)
            case .recDownload(let request): return (request.accessToken, false)
            case .getCamMap(let request): return (request.accessToken, false)
            case .camSortCCTV(let request): return (request.accessToken, false)
            case .allPlaces(let request): return (request.accessToken, request.forceRefresh)
            case .allCameras(let request): return (request.accessToken, request.forceRefresh)
                
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
                
            case .chatwootinbox(let request): return (request.accessToken, false)
            case .chatwootsend(let request): return (request.accessToken, false)
            case .chatwootsendimage(let request): return (request.accessToken, false)
            case .chatwootlist(let request): return (request.accessToken, false)

            case .getListConnect(let request): return (request.accessToken, request.forceRefresh)
            case .createIssue(let request): return (request.accessToken, false)
            case .actionIssue(let request): return (request.accessToken, false)
            case .commentIssue(let request): return (request.accessToken, false)
                
            case .appVersion(let request): return (request.accessToken, false)
            case .appLogout(let request): return (request.accessToken, false)
            case .addMyPhone(let request): return (request.accessToken, false)
            case .registerPushToken(let request): return (request.accessToken, false)
            case .checkOfferta(let request): return (request.accessToken, false)
            case .acceptOfferta(let request): return (request.accessToken, false)

            case .getPaymentsList(let request): return (request.accessToken, request.forceRefresh)
            case .sendName(let request): return (request.accessToken, false)
            case .restore(let request): return (request.accessToken, false)
            case .notification(let request): return (request.accessToken, false)

            case .payPrepare(let request): return (request.accessToken, false)
            case .payProcess(let request): return (request.accessToken, false)
            case .sberbankRegister(let request): return (request.accessToken, false) // TODO
                
            case .extList(let request): return (request.accessToken, false)
            case .ext(let request): return (request.accessToken, false)
            case .options(let request): return (request.accessToken, false)
                
            case .getPersonFaces(let request): return (request.accessToken, request.forceRefresh)
            case .removePersonFace(let request): return (request.accessToken, false)
            case .likePersonFace(let request): return (request.accessToken, false)
            case .disLikePersonFace(let request): return (request.accessToken, false)
                
            case .payBalanceDetail(let request): return (request.accessToken, false)
            case .paySendDetail(let request): return (request.accessToken, false)
            case .payGetCards(let request): return (request.accessToken, false)
            case .payAuto(let request): return (request.accessToken, false)
            case .payNew(let request): return (request.accessToken, false)
            case .payCheck(let request): return (request.accessToken, false)
            case .payRemoveCard(let request): return (request.accessToken, false)
            case .addAutopay(let request): return (request.accessToken, false)
            case .removeAutopay(let request): return (request.accessToken, false)
            case .newSBPPay(let request): return (request.accessToken, false)
            case .updateSBPPay(let request): return (request.accessToken, false)
            case .yooKassaNewPay(let request): return (request.accessToken, false)

            case .activateLimit(let request): return (request.accessToken, false)
                
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
//        case .sberbankRegister: return [:] //TODO
        default: return defaultHeaders.merging(additionalHeaders) { _, new in new }
        }
    }
    
    var task: Task {
        switch self {
        case .streamInfo, .sberbankRegister:
            return .requestParameters(parameters: requestParameters, encoding: URLEncoding.default)
        default:
            return .requestParameters(parameters: requestParameters, encoding: JSONEncoding.default)
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
        case .plog(let request): return request.requestParameters
        case .plogDays(let request): return request.requestParameters
        case .shareGenerate(let request): return request.requestParameters
        case .getContracts(let request): return request.requestParameters
        case .setParentControl(let request): return request.requestParameters
        
        case .allCCTV(let request): return request.requestParameters
        case .camCCTV(let request): return request.requestParameters
        case .cityCoordinate(let request): return request.requestParameters
        case .overviewCCTV(let request): return request.requestParameters
        case .youtube(let request): return request.requestParameters
        case .recPrepare(let request): return request.requestParameters
        case .recSize(let request): return request.requestParameters
        case .recDownload(let request): return request.requestParameters
        case .getCamMap(let request): return request.requestParameters
        case .streamInfo(let request): return request.requestParameters
        case .camSortCCTV(let request): return request.requestParameters
        case .allPlaces(let request): return request.requestParameters
        case .allCameras(let request): return request.requestParameters
            
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
            
        case .chatwootinbox(let request): return request.requestParameters
        case .chatwootsend(let request): return request.requestParameters
        case .chatwootsendimage(let request): return request.requestParameters
        case .chatwootlist(let request): return request.requestParameters

        case .getListConnect(let request): return request.requestParameters
        case .createIssue(let request): return request.requestParameters
        case .actionIssue(let request): return request.requestParameters
        case .commentIssue(let request): return request.requestParameters
            
        case .appVersion(let request): return request.requestParameters
        case .appLogout(let request): return request.requestParameters
        case .addMyPhone(let request): return request.requestParameters
        case .requestCode(let request): return request.requestParameters
        case .registerPushToken(let request): return request.requestParameters
        case .confirmCode(let request): return request.requestParameters
        case .checkPhone(let request): return request.requestParameters
        case .acceptOfferta(let request): return request.requestParameters
        case .checkOfferta(let request): return request.requestParameters
        
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
            
        case .payBalanceDetail(let request): return request.requestParameters
        case .paySendDetail(let request): return request.requestParameters
        case .payGetCards(let request): return request.requestParameters
        case .payAuto(let request): return request.requestParameters
        case .payNew(let request): return request.requestParameters
        case .payCheck(let request): return request.requestParameters
        case .payRemoveCard(let request): return request.requestParameters
        case .addAutopay(let request): return request.requestParameters
        case .removeAutopay(let request): return request.requestParameters
        case .newSBPPay(let request): return request.requestParameters
        case .updateSBPPay(let request): return request.requestParameters
        case .yooKassaNewPay(let request): return request.requestParameters

        case .activateLimit(let request): return request.requestParameters
            
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
}
// swiftlint:enable closure_body_length
