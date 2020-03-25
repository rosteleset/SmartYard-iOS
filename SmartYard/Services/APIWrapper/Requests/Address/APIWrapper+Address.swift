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
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = RegisterQRRequest(accessToken: accessToken, qr: qr)
        
        return provider.rx
            .request(.registerQR(request: request))
            .filterSuccessfulCodes()
            .map(BaseAPIResponse<String>.self)
            .flatMap { response in
                if let errorDescription = response.data {
                    return .error(NSError.APIWrapperError.qrRegistrationFailed(reason: errorDescription))
                }
                
                return .just(())
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
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = IntercomRequest(accessToken: accessToken, flatId: flatId, settings: settings)
        
        return provider.rx
            .request(.intercom(request: request))
            .filterSuccessfulCodes()
            .map(BaseAPIResponse<IntercomResponseData>.self)
            .flatMap { response in
                guard let data = response.data else {
                    return .error(NSError.APIWrapperError.noDataError)
                }
                
                return .just(data)
            }
    }
    
    func openDoor(domophoneId: String, doorId: Int?, blockReason: String?) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        if let blockReason = blockReason {
            return .error(NSError.APIWrapperError.doorBlockedError(reason: blockReason))
        }
        
        let request = OpenDoorRequest(accessToken: accessToken, domophoneId: domophoneId, doorId: doorId)
        
        return provider.rx
            .request(.openDoor(request: request))
            .filterSuccessfulCodes()
            .map { _ in }
    }
    
    func resetCode(flatId: String) -> Single<ResetCodeResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = ResetCodeRequest(accessToken: accessToken, flatId: flatId)
        
        return provider.rx
            .request(.resetCode(request: request))
            .filterSuccessfulCodes()
            .map(BaseAPIResponse<ResetCodeResponseData>.self)
            .flatMap { response in
                guard let data = response.data else {
                    return .error(NSError.APIWrapperError.noDataError)
                }
                
                return .just(data)
            }
    }
    
    func getSettingsAddresses() -> Single<GetSettingsListResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetSettingsListRequest(accessToken: accessToken)
        
        return provider.rx
            .request(.getSettingsList(request: request))
            .filterSuccessfulCodes()
            .mapAsEmptyDataInitializable()
            .mapToOptional()
    }
    
    func getAddressList() -> Single<GetAddressListResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetAddressListRequest(accessToken: accessToken)
        
        return provider.rx
            .request(.getAddressList(request: request))
            .filterSuccessfulCodes()
            .mapAsEmptyDataInitializable()
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
            .filterSuccessfulCodes()
            .map { _ in }
    }
    
    func resendSMS(flatId: String, guestPhone: String) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = ResendRequest(accessToken: accessToken, flatId: flatId, guestPhone: guestPhone)
        
        return provider.rx
            .request(.resend(request: request))
            .filterSuccessfulCodes()
            .map { _ in }
    }
    
    func getOffices() -> Single<OfficesResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = OfficesRequest(accessToken: accessToken)
        
        return provider.rx
            .request(.offices(request: request))
            .filterSuccessfulCodes()
            .mapAsEmptyDataInitializable()
            .mapToOptional()
    }
    
}
