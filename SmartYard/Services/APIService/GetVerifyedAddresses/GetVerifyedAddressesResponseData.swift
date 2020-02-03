//
//  GetVerifyedAddressesResponseData.swift
//  SmartYard
//
//  Created by admin on 03/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

struct GetVerifyedAddressesResponseData: Decodable {
    
    let clientId: String
    let login: String
    let contractName: String
    let clientName: String
    let address: String
    let looser: String
    let flatId: String
    let flatNumber: String
    let houseId: String
    let domophoneId: String
    
    private enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case login = "login"
        case contractName = "contract_name"
        case clientName = "client_name"
        case address = "address"
        case looser = "looser"
        case flatId = "flat_id"
        case flatNumber = "flat_number"
        case houseId = "house_id"
        case domophoneId = "domophone_id"
    }
    
}
