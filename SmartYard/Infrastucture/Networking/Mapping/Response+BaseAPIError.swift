//
//  Response+BaseAPIError.swift
//  SmartYard
//
//  Created by Александр Попов on 21.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import Foundation
import Moya

extension Response {
    func extractBaseAPIResponseError() -> Error {
        struct BaseAPIErrorResponse: Decodable {
            let code: Int?
            let message: String?
        }

        do {
            let mappedResponse = try map(BaseAPIErrorResponse.self)
            let mappedCode = mappedResponse.code ?? statusCode
            let mappedMessage = mappedResponse.message?.trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

            guard !mappedMessage.isEmpty else {
                return NSError.APIWrapperError.codeIsNotSuccessful(mappedCode)
            }

            return NSError.APIWrapperError.codeIsNotSuccessfulExtended(
                code: mappedCode,
                message: mappedMessage
            )
        } catch {
            return NSError.APIWrapperError.codeIsNotSuccessful(statusCode)
        }
    }
}
