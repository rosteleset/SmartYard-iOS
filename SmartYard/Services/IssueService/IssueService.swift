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
    private let disposeBag = DisposeBag()
    
    init(apiWrapper: APIWrapper) {
        self.apiWrapper = apiWrapper
    }
    
    // экран 00.01
    func sendAddressApproveIssue(address: String) -> Driver<CreateIssueResponseData?> {
        return getAddressCoordinates(address: address)
            .asDriver(onErrorJustReturn: nil)
            .flatMapLatest { [weak self] coordinates -> Driver<CreateIssueResponseData?> in
                guard let self = self else {
                    return .just(nil)
                }
                
                return self.apiWrapper.createIssue(
                    issue: .approveAddressIssue(address: address),
                    userInfo: nil,
                    selectedService: nil,
                    lat: coordinates?.lat,
                    lng: coordinates?.lon
                    )
                    .asDriver(onErrorJustReturn: nil)
            }
    }
    
    // экран 19 и 34.00
    func sendNothingRememberIssue(userInfo: MainUserInfo, services: [SettingsServiceType]) {
        
    }
    
    // экран 21
    func sendUnavailableAddressConnectionIssue(userInfo: MainUserInfo, services: [SettingsServiceType]) {
        
    }
    
    // экран 22
    func sendConnectSelectedServicesIssue(userInfo: MainUserInfo, services: [SettingsServiceType]) {
        
    }
    
    // экраны 23, 29
    func sendApproveAddressByCourierIssue(userInfo: MainUserInfo) {
        
    }
    
    // экраны 24, 28
    func sendApproveAddressInOfficeIssue(userInfo: MainUserInfo) {
        
    }
    
    // экран 34
    func sendActivateServiceIssue(userInfo: MainUserInfo) {
        
    }
    
    // экран 34.02.03
    func sendDeleteAddressIssue(userInfo: MainUserInfo, reason: String) {
        
    }
    
    // экран 34.03
    func sendChangeTariffIssue(clientId: String) {
        
    }
    
    // экран 34.05
    func sendServiceUnavailableIssue(userInfo: MainUserInfo, service: SettingsServiceType) {
        
    }
    
    private func getAddressCoordinates(address: String) -> Single<GeoCoderResponseData?> {
        return apiWrapper.getCoordinatesByAddress(address: address)
    }
}
