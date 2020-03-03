//
//  IssueService.swift
//  SmartYard
//
//  Created by Mad Brains on 28.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class IssueService {
    
    private let apiWrapper: APIWrapper
    private let accessService: AccessService
    
    private let disposeBag = DisposeBag()
    
    init(apiWrapper: APIWrapper, accessService: AccessService) {
        self.apiWrapper = apiWrapper
        self.accessService = accessService
    }
    
    // экран 00.01
    func sendAddressApproveIssue(address: String) -> Single<CreateIssueResponseData?> {
        return sendIssueWithLocation(
            issue: .approveAddressIssue(address: address),
            address: address
        )
    }
    
    // экран 19 и 34.00
    func sendNothingRememberIssue() -> Single<CreateIssueResponseData?> {
        return sendSimpleIssue(
            issue: .dontRememberAnythingIssue(
                userInfo: getUserInfo(
                    address: nil,
                    clientId: nil
                )
            )
        )
    }
    
    // экран 21
    func sendUnavailableAddressConnectionIssue(
        address: String,
        services: [SettingsServiceType]
    ) -> Single<CreateIssueResponseData?> {
        return sendIssueWithLocation(
            issue: .unavailableAddressConnectionIssue(
                userInfo: getUserInfo(
                    address: address,
                    clientId: nil
                ),
                services: services
            ),
            address: address
        )
    }
    
    // экран 22
    func sendConnectSelectedServicesIssue(
        address: String,
        services: [SettingsServiceType]
    ) -> Single<CreateIssueResponseData?> {
        return sendIssueWithLocation(
            issue: .connectSelectedServicesIssue(
                userInfo: getUserInfo(
                    address: address,
                    clientId: nil
                ),
                services: services
            ),
            address: address
        )
    }
    
    // экраны 23, 29
    func sendApproveAddressByCourierIssue(address: String) -> Single<CreateIssueResponseData?> {
        return sendIssueWithLocation(
            issue: .confirmAddressByCourierIssue(
                userInfo: getUserInfo(
                    address: address,
                    clientId: nil
                )
            ),
            address: address
        )
    }
    
    // экраны 24, 28
    func sendApproveAddressInOfficeIssue(address: String) -> Single<CreateIssueResponseData?> {
        return sendIssueWithLocation(
            issue: .confirmAddressInOfficeIssue(
                userInfo: getUserInfo(
                    address: address,
                    clientId: nil
                )
            ),
            address: address
        )
    }
    
    // экран 34.04
    func sendActivateServiceIssue(
        address: String,
        services: [SettingsServiceType]
    ) -> Single<CreateIssueResponseData?> {
        return sendIssueWithLocation(
            issue: .activateServiceIssue(
                userInfo: getUserInfo(
                    address: address,
                    clientId: nil
                ),
                services: services
            ),
            address: address
        )
    }
    
    // экран 34.02.03
    func sendDeleteAddressIssue(address: String, reason: String) -> Single<CreateIssueResponseData?> {
        return sendIssueWithLocation(
            issue: .deleteAddressIssue(
                userInfo: getUserInfo(
                    address: address,
                    clientId: nil
                ),
                reason: reason
            ),
            address: address
        )
    }
    
    // экран 34.03
    func sendChangeTariffIssue(clientId: String?) -> Single<CreateIssueResponseData?> {
        guard let clientId = clientId else {
            return .error(NSError.APIWrapperError.clientIdMissingError)
        }
        
        return sendSimpleIssue(
            issue: .changeTariffIssue(clientId: clientId)
        )
    }
    
    // экран 34.05
    func sendServiceUnavailableIssue(
        address: String,
        service: SettingsServiceType,
        clientId: String?
    ) -> Single<CreateIssueResponseData?> {
        guard let clientId = clientId else {
            return .error(NSError.APIWrapperError.clientIdMissingError)
        }
        
        return sendIssueWithLocation(
            issue: .serviceUnavailableIssue(
                userInfo: getUserInfo(
                    address: address,
                    clientId: clientId
                ),
                service: service
            ),
            address: address
        )
    }
    
    private func sendIssueWithLocation(issue: IssueType, address: String) -> Single<CreateIssueResponseData?> {
        return getAddressCoordinates(address: address)
            .flatMap { [weak self] response -> Single<CreateIssueResponseData?> in
                guard let self = self, let unwrappedResponse = response else {
                    return .error(NSError.GenericError.selfIsDeadError)
                }
                
                return self.apiWrapper.createIssue(
                    issue: issue,
                    userInfo: self.getUserInfo(address: address, clientId: nil),
                    lat: unwrappedResponse.lat,
                    lng: unwrappedResponse.lon
                )
            }
    }
    
    private func sendSimpleIssue(issue: IssueType) -> Single<CreateIssueResponseData?> {
        return self.apiWrapper.createIssue(
            issue: issue,
            userInfo: self.getUserInfo(address: nil, clientId: issue.clientCode),
            lat: "",
            lng: ""
        )
    }
    
    private func getAddressCoordinates(address: String) -> Single<GeoCoderResponseData?> {
        return apiWrapper.getCoordinatesByAddress(address: address)
    }
    
    private func getUserInfo(address: String?, clientId: String?) -> MainUserInfo {
        return MainUserInfo(
            fullName: self.accessService.clientName?.name ?? "",
            phoneNumber: self.accessService.clientPhoneNumber ?? "",
            clientId: clientId,
            address: address ?? ""
        )
    }
    
}
