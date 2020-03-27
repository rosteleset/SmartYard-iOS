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
    
    // экран 19 и 34.00
    func sendNothingRememberIssue() -> Single<CreateIssueResponseData?> {
        let issue = Issue(issueType: .dontRememberAnythingIssue(userInfo: getUserInfo(address: nil, clientId: nil)))
        return apiWrapper.sendIssue(issue: issue)
    }
    
    // экраны 23, 29
    func sendApproveAddressByCourierIssue(address: String) -> Single<CreateIssueResponseData?> {
        return getAddressCoordinates(address: address)
            .flatMap { [weak self] response -> Single<CreateIssueResponseData?> in
                guard let self = self, let unwrappedResponse = response else {
                    return .error(NSError.GenericError.selfIsDeadError)
                }
                
                let latitude = unwrappedResponse.lat.replacingOccurrences(of: ".", with: ",")
                let longitude = unwrappedResponse.lon.replacingOccurrences(of: ".", with: ",")

                let issue = Issue(
                    issueType: .confirmAddressByCourierIssue(
                        userInfo: self.getUserInfo(address: address, clientId: nil),
                        lat: latitude,
                        lon: longitude
                    )
                )
                
                return self.apiWrapper.sendIssue(issue: issue)
            }
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
        return
    }
    
    
    // экраны 24, 28
    func sendApproveAddressInOfficeIssue(address: String) -> Single<CreateIssueResponseData?> {
        return .just(nil)
    }
    
    // экран 34.02.03
    func sendDeleteAddressIssue(address: String, reason: String) -> Single<CreateIssueResponseData?> {
        return .just(nil)
    }
    
    // экран 34.03
    func sendChangeTariffIssue(clientId: String?) -> Single<CreateIssueResponseData?> {
        guard let clientId = clientId else {
            return .error(NSError.APIWrapperError.clientIdMissingError)
        }
        
        return .just(nil)
    }
    
    private func sendIssueWithLocation(issue: IssueType, address: String) -> Single<CreateIssueResponseData?> {
        return getAddressCoordinates(address: address)
            .flatMap { [weak self] response -> Single<CreateIssueResponseData?> in
                guard let self = self, let unwrappedResponse = response else {
                    return .error(NSError.GenericError.selfIsDeadError)
                }

                return self.apiWrapper.sendIssue(issue: <#T##Issue#>)
        }
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
