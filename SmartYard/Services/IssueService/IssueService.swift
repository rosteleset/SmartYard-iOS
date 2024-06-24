//
//  IssueService.swift
//  SmartYard
//
//  Created by Mad Brains on 28.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
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
    // экран 37 - Запрос записи
    func sendRequestRecIssue(camera: CityCameraObject, date: Date, duration: Int, notes: String) -> Single<CreateIssueResponseData?> {
        
        switch accessService.issuesVersion {
        case "2":
            let issue = IssueV2(
                type: .requestFragment,
                userName: accessService.clientName?.name,
                comments: notes,
                cameraId: camera.id.string,
                cameraName: camera.name, 
                fragmentDate: date.string(withFormat: "d.MM.yyyy"),
                fragmentTime: date.timeString(),
                fragmentDuration: duration.string
            )
            return apiWrapper.sendIssue(issueV2: issue)
        default:
            let issue = Issue(
                issueType: .requestRec(
                    camera: camera,
                    date: date,
                    duration: duration,
                    notes: notes
                )
            )
            return apiWrapper.sendIssue(issueV1: issue)
        }
    }
    
    // экран 35 - Меню
    func sendCallbackIssue() -> Single<CreateIssueResponseData?> {
        
        switch accessService.issuesVersion {
        case "2":
            let issue = IssueV2(
                type: .requestCallback,
                userName: accessService.clientName?.name
            )
            return apiWrapper.sendIssue(issueV2: issue)
        default:
            let issue = Issue(issueType: .orderCallback)
            return apiWrapper.sendIssue(issueV1: issue)
        }
    }
    
    // экран 19 и 34.00
    func sendNothingRememberIssue() -> Single<CreateIssueResponseData?> {
        
        switch accessService.issuesVersion {
        case "2":
            let issue = IssueV2(
                type: .requestCredentials,
                userName: accessService.clientName?.name
            )
            return apiWrapper.sendIssue(issueV2: issue)
        default:
            let issue = Issue(issueType: .dontRememberAnythingIssue(userInfo: getUserInfo(address: nil, clientId: nil)))
            return apiWrapper.sendIssue(issueV1: issue)
        }
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

                switch accessService.issuesVersion {
                case "2":
                    let issue = IssueV2(
                        type: .requestQRCodeCourier,
                        userName: accessService.clientName?.name,
                        inputAddress: address
                    )
                    return apiWrapper.sendIssue(issueV2: issue)
                default:
                    let issue = Issue(
                        issueType: .confirmAddressByCourierIssue(
                            userInfo: self.getUserInfo(address: address, clientId: nil),
                            lat: latitude,
                            lon: longitude
                        )
                    )
                    return apiWrapper.sendIssue(issueV1: issue)
                }
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
                
                switch accessService.issuesVersion {
                case "2":
                    let issue = IssueV2(
                        type: .requestQRCodeOffice,
                        userName: accessService.clientName?.name,
                        inputAddress: address
                    )
                    return apiWrapper.sendIssue(issueV2: issue)
                default:
                    let issue = Issue(
                        issueType: .confirmAddressInOfficeIssue(
                            userInfo: self.getUserInfo(address: address, clientId: nil),
                            lat: latitude,
                            lon: longitude
                        )
                    )
                    return apiWrapper.sendIssue(issueV1: issue)
                }
            }
    }
    
    // экран 34.02.03
    func sendDeleteAddressIssue(address: String, reason: String) -> Single<CreateIssueResponseData?> {
        return getAddressCoordinates(address: address)
            .flatMap { [weak self] response -> Single<CreateIssueResponseData?> in
                guard let self = self, let unwrappedResponse = response else {
                    return .error(NSError.GenericError.selfIsDeadError)
                }
                
                let latitude = unwrappedResponse.lat.replacingOccurrences(of: ".", with: ",")
                let longitude = unwrappedResponse.lon.replacingOccurrences(of: ".", with: ",")
                  
                switch accessService.issuesVersion {
                case "2":
                    let issue = IssueV2(
                        type: .removeAddress,
                        userName: accessService.clientName?.name,
                        inputAddress: address,
                        comments: reason
                    )
                    return apiWrapper.sendIssue(issueV2: issue)
                default:
                    let issue = Issue(
                        issueType: .deleteAddressIssue(
                            userInfo: self.getUserInfo(address: address, clientId: nil),
                            lat: latitude,
                            lon: longitude,
                            reason: reason
                        )
                    )
                    return apiWrapper.sendIssue(issueV1: issue)
                }
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

                switch accessService.issuesVersion {
                case "2":
                    let issue = IssueV2(
                        type: .connectServicesNoNetwork,
                        userName: accessService.clientName?.name,
                        inputAddress: address,
                        services: serviceNames.joined(separator: ", ")
                    )
                    return apiWrapper.sendIssue(issueV2: issue)
                default:
                    let issue = Issue(
                        issueType: .servicesUnavailableIssue(
                            userInfo: self.getUserInfo(address: address, clientId: nil),
                            serviceNames: serviceNames,
                            lat: latitude,
                            lon: longitude
                        )
                    )
                    return apiWrapper.sendIssue(issueV1: issue)
                }
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
                                
                switch accessService.issuesVersion {
                case "2":
                    let issue = IssueV2(
                        type: .connectServicesHasCommon,
                        userName: accessService.clientName?.name,
                        inputAddress: address,
                        services: serviceNames.joined(separator: ", ")
                    )
                    return apiWrapper.sendIssue(issueV2: issue)
                default:
                    let issue = Issue(
                        issueType: .comeInOfficeMyselfIssue(
                            userInfo: self.getUserInfo(address: address, clientId: nil),
                            lat: latitude,
                            lon: longitude,
                            serviceNames: serviceNames
                        )
                    )
                    return apiWrapper.sendIssue(issueV1: issue)
                }
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
                                
                switch accessService.issuesVersion {
                case "2":
                    let issue = IssueV2(
                        type: .connectServicesNoCommon,
                        userName: accessService.clientName?.name,
                        inputAddress: address,
                        services: serviceNames.joined(separator: ", ")
                    )
                    return apiWrapper.sendIssue(issueV2: issue)
                default:
                    let issue = Issue(
                        issueType: .connectOnlyNonHousesServices(
                            userInfo: self.getUserInfo(
                                address: address,
                                clientId: nil
                            ),
                            lat: latitude,
                            lon: longitude,
                            serviceNames: serviceNames
                        )
                    )
                    return self.apiWrapper.sendIssue(issueV1: issue)
                }
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
