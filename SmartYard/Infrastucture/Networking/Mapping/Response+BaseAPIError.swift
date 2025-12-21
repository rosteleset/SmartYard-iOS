//
//  Response+BaseAPIError.swift
//  SmartYard
//
//  Created by Александр Попов on 21.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import Moya

extension Response {
    func extractBaseAPIResponseError() -> Error {
        do {
            let mappedResponse = try map(BaseAPIResponse<String>.self)

            return NSError.APIWrapperError.codeIsNotSuccessfulExtended(
                code: mappedResponse.code,
                message: mappedResponse.message
            )
        } catch {
            return NSError.APIWrapperError.codeIsNotSuccessful(statusCode)
        }
    }
}
