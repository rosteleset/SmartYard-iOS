//
//  AddLicensePlateRequest.swift
//  SmartYard
//
//  Created by Александр Попов on 09.06.2025.
//  Copyright © 2025 Sesameware. All rights reserved.
//

import Foundation

struct AddLicensePlateRequest {
    let accessToken: String
    let flatId: Int
    let number: String
    let countryCode: String?
    let validity: LicensePlateValidity

    init(
        accessToken: String,
        flatId: Int,
        number: String,
        countryCode: String? = nil,
        validity: LicensePlateValidity = .unlimited
    ) {
        self.accessToken = accessToken
        self.flatId = flatId
        self.number = number
        self.countryCode = countryCode
        self.validity = validity
    }

    var requestParameters: [String: Any] {
        var parameters: [String: Any] = ["flatId": flatId, "number": number]
        if let countryCode {
            parameters["countryCode"] = countryCode
            parameters["validFrom"] = validity.validFrom.map { LicensePlateValidity.apiString(from: $0) as Any } ?? NSNull()
            parameters["validTo"] = validity.validTo.map { LicensePlateValidity.apiString(from: $0) as Any } ?? NSNull()
        }
        return parameters
    }
}
