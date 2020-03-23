//
//  APIWrapper+Address.swift
//  SmartYard
//
//  Created by admin on 23/03/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension APIWrapper {
    
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
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performIntercomRequest(request) { result in
                switch result {
                case let .success(data): single(.success(data))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
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
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performOpenDoorRequest(request) { result in
                switch result {
                case .success: single(.success(()))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func resetCode(flatId: String) -> Single<ResetCodeResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = ResetCodeRequest(accessToken: accessToken, flatId: flatId)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performResetCodeRequest(request) { result in
                switch result {
                case let .success(data): single(.success(data))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func getSettingsAddresses() -> Single<GetSettingsListResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetSettingsListRequest(accessToken: accessToken)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performSettingsListRequest(request) { result in
                switch result {
                case let .success(data): single(.success(data))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func getAddressList() -> Single<GetAddressListResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetAddressListRequest(accessToken: accessToken)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performGetAddressListRequest(request) { result in
                switch result {
                case let .success(data): single(.success(data))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
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
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performAccessRequest(request) { result in
                switch result {
                case .success: single(.success(()))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func resendSMS(flatId: String, guestPhone: String) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = ResendRequest(accessToken: accessToken, flatId: flatId, guestPhone: guestPhone)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performResendRequest(request) { result in
                switch result {
                case .success: single(.success(()))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
}
