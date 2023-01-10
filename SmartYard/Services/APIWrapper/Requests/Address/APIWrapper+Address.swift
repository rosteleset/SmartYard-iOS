//
//  APIWrapper+Address.swift
//  SmartYard
//
//  Created by admin on 23/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Moya

extension APIWrapper {
    
    func registerQR(qr: String) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = RegisterQRRequest(accessToken: accessToken, qr: qr)
        
        return provider.rx
            .request(.registerQR(request: request))
            .convertNoConnectionError()
            .flatMap { response in
                // MARK: Если code == 204, значит, что регистрация успешно выполнилась
                
                if response.statusCode == 204 {
                    return .just(())
                }
                
                // MARK: Если code == 200, значит, что-то пошло не так
                // Да, 200 - значит, что-то не так. Достаем информацию об этом из респонза
                
                if response.statusCode == 200 {
                    do {
                        let mappedResponse = try response.map(BaseAPIResponse<String>.self)
                        
                        if let errorDescription = mappedResponse.data {
                            return .error(NSError.APIWrapperError.qrRegistrationFailed(reason: errorDescription))
                        } else {
                            return .error(NSError.APIWrapperError.noDataError)
                        }
                    } catch {
                        return .error(NSError.APIWrapperError.baseResponseMappingError)
                    }
                }
                
                // MARK: Если код отличается от 200 и от 204, пытаемся достать информацию об ошибке
                
                return .error(response.extractBaseAPIResponseError())
            }
    }
    
    func getCurrentIntercomState(flatId: String) -> Single<IntercomResponseData?> {
        return intercom(flatId: flatId, forceRefresh: true, settings: nil)
    }
    
    func grantHourGuestAccess(flatId: String) -> Single<IntercomResponseData?> {
        let settings = APIIntercomSettings(
            enableDoorCode: nil,
            cms: nil,
            voip: nil,
            autoOpen: Date().dateHourAfter,
            whiteRabbit: nil,
            paperBill: nil,
            disablePlog: nil,
            hiddenPlog: nil,
            frsDisabled: nil
        )
        
        return intercom(flatId: flatId, forceRefresh: true, settings: settings)
    }
    
    func setIntercomCMSState(flatId: String, isEnabled: Bool) -> Single<IntercomResponseData?> {
        let settings = APIIntercomSettings(
            enableDoorCode: nil,
            cms: isEnabled,
            voip: nil,
            autoOpen: nil,
            whiteRabbit: nil,
            paperBill: nil,
            disablePlog: nil,
            hiddenPlog: nil,
            frsDisabled: nil
        )
        
        return intercom(flatId: flatId, forceRefresh: true, settings: settings)
    }
    
    func setIntercomVoIPState(flatId: String, isEnabled: Bool) -> Single<IntercomResponseData?> {
        let settings = APIIntercomSettings(
            enableDoorCode: nil,
            cms: nil,
            voip: isEnabled,
            autoOpen: nil,
            whiteRabbit: nil,
            paperBill: nil,
            disablePlog: nil,
            hiddenPlog: nil,
            frsDisabled: nil
        )
        
        return intercom(flatId: flatId, forceRefresh: true, settings: settings)
    }
    
    func setIntercomWhiteRabbitState(flatId: String, isEnabled: Bool) -> Single<IntercomResponseData?> {
        let settings = APIIntercomSettings(
            enableDoorCode: nil,
            cms: nil,
            voip: nil,
            autoOpen: nil,
            whiteRabbit: isEnabled,
            paperBill: nil,
            disablePlog: nil,
            hiddenPlog: nil,
            frsDisabled: nil
        )
        
        return intercom(flatId: flatId, forceRefresh: true, settings: settings)
    }
    
    func setIntercomPaperBillState(flatId: String, isEnabled: Bool) -> Single<IntercomResponseData?> {
        let settings = APIIntercomSettings(
            enableDoorCode: nil,
            cms: nil,
            voip: nil,
            autoOpen: nil,
            whiteRabbit: nil,
            paperBill: isEnabled,
            disablePlog: nil,
            hiddenPlog: nil,
            frsDisabled: nil
        )
        
        return intercom(flatId: flatId, forceRefresh: true, settings: settings)
    }
    
    func setIntercomDisablePlogState(flatId: String, isDisabled: Bool) -> Single<IntercomResponseData?> {
        let settings = APIIntercomSettings(
            enableDoorCode: nil,
            cms: nil,
            voip: nil,
            autoOpen: nil,
            whiteRabbit: nil,
            paperBill: nil,
            disablePlog: isDisabled,
            hiddenPlog: nil,
            frsDisabled: nil
        )
        
        return intercom(flatId: flatId, forceRefresh: true, settings: settings)
    }
    
    func setIntercomHiddenPlogState(flatId: String, isHidden: Bool) -> Single<IntercomResponseData?> {
        let settings = APIIntercomSettings(
            enableDoorCode: nil,
            cms: nil,
            voip: nil,
            autoOpen: nil,
            whiteRabbit: nil,
            paperBill: nil,
            disablePlog: nil,
            hiddenPlog: isHidden,
            frsDisabled: nil
        )
        
        return intercom(flatId: flatId, forceRefresh: true, settings: settings)
    }
    
    func setIntercomFRSDisabledState(flatId: String, isDisabled: Bool) -> Single<IntercomResponseData?> {
        let settings = APIIntercomSettings(
            enableDoorCode: nil,
            cms: nil,
            voip: nil,
            autoOpen: nil,
            whiteRabbit: nil,
            paperBill: nil,
            disablePlog: nil,
            hiddenPlog: nil,
            frsDisabled: isDisabled
        )
        
        return intercom(flatId: flatId, forceRefresh: true, settings: settings)
    }
    
    func intercom(flatId: String, forceRefresh: Bool = true, settings: APIIntercomSettings?) -> Single<IntercomResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = IntercomRequest(accessToken: accessToken, forceRefresh: forceRefresh, flatId: flatId, settings: settings)
        print("request data: \(request)")
        
        return provider.rx
            .request(.intercom(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    func plogDays(flatId: Int, events: EventsFilter? = .all, forceRefresh: Bool = false) -> Single<PlogDaysResponseData?> {
        return plogDays(flatId: String(flatId), events: events, forceRefresh: forceRefresh)
    }
    
    func plogDays(flatId: String, events: EventsFilter? = .all, forceRefresh: Bool = false) -> Single<PlogDaysResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = PlogDaysRequest(accessToken: accessToken, forceRefresh: forceRefresh, flatId: flatId, events: events)
        print("request data: \(request)")
        
        return provider.rx
            .request(.plogDays(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func plog(flatId: Int, fromDate: Date, forceRefresh: Bool = false) -> Single<PlogResponseData?> {
        return plog(flatId: String(flatId), fromDate: fromDate, forceRefresh: forceRefresh)
    }
    
    func plog(flatId: String, fromDate: Date, forceRefresh: Bool = false) -> Single<PlogResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = PlogRequest(accessToken: accessToken, forceRefresh: forceRefresh, flatId: flatId, fromDate: fromDate)
        print("request data: \(request)")
        
        return provider.rx
            .request(.plog(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func openDoor(domophoneId: String, doorId: Int?, blockReason: String?) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        if let blockReason = blockReason {
            return .error(NSError.APIWrapperError.doorBlockedError(reason: blockReason))
        }
        
        let request = OpenDoorRequest(accessToken: accessToken, domophoneId: domophoneId, doorId: doorId)
        
        return provider.rx
            .request(.openDoor(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func resetCode(flatId: String) -> Single<ResetCodeResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = ResetCodeRequest(accessToken: accessToken, flatId: flatId)
        
        return provider.rx
            .request(.resetCode(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
    func getSettingsAddresses(forceRefresh: Bool = false) -> Single<GetSettingsListResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let forceRefresh = forceUpdateSettings || forceRefresh
        forceUpdateSettings = false
        
        let request = GetSettingsListRequest(accessToken: accessToken, forceRefresh: forceRefresh)
        print(request)
        
        return provider.rx
            .request(.getSettingsList(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func getCamMap() -> Single<CamMapCCTVResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = CamMapCCTVRequest(accessToken: accessToken)
        
        return provider.rx
            .request(.getCamMap(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func getAddressList(forceRefresh: Bool = false) -> Single<GetAddressListResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let forceRefresh = forceUpdateAddress || forceRefresh
        forceUpdateAddress = false
        
        let request = GetAddressListRequest(accessToken: accessToken, forceRefresh: forceRefresh)
        
        return provider.rx
            .request(.getAddressList(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func grantAccess(
        flatId: String,
        guestPhone: String,
        type: APIRoommateAccessType,
        numberOfHours: Int = 24
    ) -> Single<Void?> {
        let expire: Date? = {
            guard type == .outer else {
                return nil
            }
            
            return Calendar.current.date(byAdding: .hour, value: numberOfHours, to: Date())
        }()
        
        return access(flatId: flatId, guestPhone: guestPhone, type: type, expire: expire)
    }
    
    func revokeAccess(
        flatId: String,
        clientId: String?,
        guestPhone: String,
        type: APIRoommateAccessType
    ) -> Single<Void?> {
        return access(
            flatId: flatId,
            clientId: clientId,
            guestPhone: guestPhone,
            type: type,
            expire: Date.distantPast
        )
    }
    
    func deleteAddress(flatId: String, clientId: String?) -> Single<Void?> {
        guard let phone = accessService.clientPhoneNumber else {
            return .error(NSError.APIWrapperError.userPhoneMissing)
        }
        
        return access(
            flatId: flatId,
            clientId: clientId,
            guestPhone: AccessService.shared.phonePrefix + phone,
            expire: Date.distantPast
        )
    }
    
    func access(
        flatId: String,
        clientId: String? = nil,
        guestPhone: String? = nil,
        type: APIRoommateAccessType? = nil,
        expire: Date? = nil
    ) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = AccessRequest(
            accessToken: accessToken,
            flatId: flatId,
            clientId: clientId,
            guestPhone: guestPhone,
            type: type,
            expire: expire
        )
        
        return provider.rx
            .request(.access(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func resendSMS(flatId: String, guestPhone: String) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = ResendRequest(accessToken: accessToken, flatId: flatId, guestPhone: guestPhone)
        
        return provider.rx
            .request(.resend(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func getOffices() -> Single<OfficesResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = OfficesRequest(accessToken: accessToken)
        
        return provider.rx
            .request(.offices(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
}
