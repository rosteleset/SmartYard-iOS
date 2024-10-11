//
//  IssueService.swift
//  SmartYard
//
//  Created by Mad Brains on 28.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable line_length

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
    // экран 37 - Запрос записи
    func sendRequestRecIssue(camera: CityCameraObject, date: Date, duration: Int, notes: String) -> Single<CreateIssueResponseData?> {
        let issue = Issue(issueType: .requestRec(camera: camera, date: date, duration: duration, notes: notes))
        return apiWrapper.sendIssue(issue: issue)
    }
    
    // экран 35 - Меню
    func sendCallbackIssue() -> Single<CreateIssueResponseData?> {
        let issue = Issue(issueType: .orderCallback)
        return apiWrapper.sendIssue(issue: issue)
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
    
    // экран 24
    func sendApproveAddressInOfficeIssue(address: String) -> Single<CreateIssueResponseData?> {
        return getAddressCoordinates(address: address)
            .flatMap { [weak self] response -> Single<CreateIssueResponseData?> in
                guard let self = self, let unwrappedResponse = response else {
                    return .error(NSError.GenericError.selfIsDeadError)
                }
                
                let latitude = unwrappedResponse.lat.replacingOccurrences(of: ".", with: ",")
                let longitude = unwrappedResponse.lon.replacingOccurrences(of: ".", with: ",")
                
                let issue = Issue(
                    issueType: .confirmAddressInOfficeIssue(
                        userInfo: self.getUserInfo(address: address, clientId: nil),
                        lat: latitude,
                        lon: longitude
                    )
                )
                
                return self.apiWrapper.sendIssue(issue: issue)
            }
    }
    
    // экран 34.02.03
    func sendDeleteAddressIssue(address: String, cliendId: String?, reason: String) -> Single<CreateIssueResponseData?> {
        return getAddressCoordinates(address: address)
            .flatMap { [weak self] response -> Single<CreateIssueResponseData?> in
                guard let self = self, let unwrappedResponse = response else {
                    return .error(NSError.GenericError.selfIsDeadError)
                }
                
                let latitude = unwrappedResponse.lat.replacingOccurrences(of: ".", with: ",")
                let longitude = unwrappedResponse.lon.replacingOccurrences(of: ".", with: ",")
                
                let issue = Issue(
                    issueType: .deleteAddressIssue(
                        userInfo: self.getUserInfo(address: address, clientId: cliendId),
                        lat: latitude,
                        lon: longitude,
                        clientId: cliendId ?? "",
                        reason: reason
                    )
                )
                
                return self.apiWrapper.sendIssue(issue: issue)
            }
    }
    
    // экран 21
    func sendUnavailableAddressConnectionIssue(
        address: String,
        serviceNames: [String]
    ) -> Single<CreateIssueResponseData?> {
        return getAddressCoordinates(address: address)
            .flatMap { [weak self] response -> Single<CreateIssueResponseData?> in
                guard let self = self, let unwrappedResponse = response else {
                    return .error(NSError.GenericError.selfIsDeadError)
                }
                
                let latitude = unwrappedResponse.lat.replacingOccurrences(of: ".", with: ",")
                let longitude = unwrappedResponse.lon.replacingOccurrences(of: ".", with: ",")
                
                let issue = Issue(
                    issueType: .servicesUnavailableIssue(
                        userInfo: self.getUserInfo(address: address, clientId: nil),
                        serviceNames: serviceNames,
                        lat: latitude,
                        lon: longitude
                    )
                )
                
                return self.apiWrapper.sendIssue(issue: issue)
            }
    }
    
    // экран 22 в случае, если есть общедомовые услуги и выбран какой-либо другой сервис
    func sendComeInOfficeMyselfIssue(
        address: String,
        serviceNames: [String]
    ) -> Single<CreateIssueResponseData?> {
        return getAddressCoordinates(address: address)
            .flatMap { [weak self] response -> Single<CreateIssueResponseData?> in
                guard let self = self, let unwrappedResponse = response else {
                    return .error(NSError.GenericError.selfIsDeadError)
                }
                
                let latitude = unwrappedResponse.lat.replacingOccurrences(of: ".", with: ",")
                let longitude = unwrappedResponse.lon.replacingOccurrences(of: ".", with: ",")
                
                let issue = Issue(
                    issueType: .comeInOfficeMyselfIssue(
                        userInfo: self.getUserInfo(address: address, clientId: nil),
                        lat: latitude,
                        lon: longitude,
                        serviceNames: serviceNames
                    )
                )
                
                return self.apiWrapper.sendIssue(issue: issue)
            }
    }
    
    // экран 22, кейс, когда нет общедомовых услуг
    func sendConnectOnlyNonHousesServicesIssue(
        address: String,
        serviceNames: [String]
    ) -> Single<CreateIssueResponseData?> {
        return getAddressCoordinates(address: address)
            .flatMap { [weak self] response -> Single<CreateIssueResponseData?> in
                guard let self = self, let unwrappedResponse = response else {
                    return .error(NSError.GenericError.selfIsDeadError)
                }
                
                let latitude = unwrappedResponse.lat.replacingOccurrences(of: ".", with: ",")
                let longitude = unwrappedResponse.lon.replacingOccurrences(of: ".", with: ",")
                
                let issue = Issue(
                    issueType: .connectOnlyNonHousesServices(
                        userInfo: self.getUserInfo(address: address, clientId: nil),
                        lat: latitude,
                        lon: longitude,
                        serviceNames: serviceNames
                    )
                )
                
                return self.apiWrapper.sendIssue(issue: issue)
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
// swiftlint:enable line_length
