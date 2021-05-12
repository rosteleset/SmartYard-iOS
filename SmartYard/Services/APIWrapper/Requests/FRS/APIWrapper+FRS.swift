//
//  APIWrapper+FRS.swift
//  SmartYard
//
//  Created by Александр Васильев on 12.05.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension APIWrapper {
    
    func getPersonFaces() -> Single<GetPersonFacesResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetPersonFacesRequest(accessToken: accessToken)
        
        return provider.rx
            .request(.getPersonFaces(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    
    
}
