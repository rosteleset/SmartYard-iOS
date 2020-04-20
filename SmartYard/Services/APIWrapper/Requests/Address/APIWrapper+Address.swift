//
//  APIWrapper+Address.swift
//  SmartYard
//
//  Created by admin on 23/03/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

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
        return intercom(flatId: flatId, settings: nil)
    }
    
    func grantHourGuestAccess(flatId: String) -> Single<IntercomResponseData?> {
        let settings = APIIntercomSettings(
            enableDoorCode: nil,
            cms: nil,
            voip: nil,
            autoOpen: Date().dateHourAfter,
            whiteRabbit: nil
        )
        
        return intercom(flatId: flatId, settings: settings)
    }
    
    func setIntercomCMSState(flatId: String, isEnabled: Bool) -> Single<IntercomResponseData?> {
        let settings = APIIntercomSettings(
            enableDoorCode: nil,
            cms: isEnabled,
            voip: nil,
            autoOpen: nil,
            whiteRabbit: nil
        )
        
        return intercom(flatId: flatId, settings: settings)
    }
    
    func setIntercomVoIPState(flatId: String, isEnabled: Bool) -> Single<IntercomResponseData?> {
        let settings = APIIntercomSettings(
            enableDoorCode: nil,
            cms: nil,
            voip: isEnabled,
            autoOpen: nil,
            whiteRabbit: nil
        )
        
        return intercom(flatId: flatId, settings: settings)
    }
    
    func intercom(flatId: String, settings: APIIntercomSettings?) -> Single<IntercomResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = IntercomRequest(accessToken: accessToken, flatId: flatId, settings: settings)
        
        return provider.rx
            .request(.intercom(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
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
    
    func getSettingsAddresses() -> Single<GetSettingsListResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetSettingsListRequest(accessToken: accessToken)
        
        return provider.rx
            .request(.getSettingsList(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func getAddressList() -> Single<GetAddressListResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetAddressListRequest(accessToken: accessToken)
        
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
    
    func revokeAccess(flatId: String, guestPhone: String, type: APIRoommateAccessType) -> Single<Void?> {
        return access(flatId: flatId, guestPhone: guestPhone, type: type, expire: Date.distantPast)
    }
    
    func deleteAddress(flatId: String) -> Single<Void?> {
        guard let phone = accessService.clientPhoneNumber else {
            return .error(NSError.APIWrapperError.userPhoneMissing)
        }
        
        return access(flatId: flatId, guestPhone: "8" + phone, expire: Date.distantPast)
    }
    
    func access(
        flatId: String,
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
