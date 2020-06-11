//
//  ApiWrapper+CCTV.swift
//  SmartYard
//
//  Created by admin on 01.06.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension APIWrapper {
    
    func getAllCCTV(houseId: String?) -> Single<AllCCTVResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = AllCCTVRequest(accessToken: accessToken, houseId: houseId)
        
        return provider.rx
            .request(.allCCTV(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func recPrepare(id: Int, from: String, to: String) -> Single<Int?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = RecPrepareRequest(accessToken: accessToken, id: id, from: from, to: to)
        
        return provider.rx
            .request(.recPrepare(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
}
