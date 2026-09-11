//
//  APIPaymentsListAddress.swift
//  SmartYard
//
//  Created by admin on 25/02/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

struct APIPaymentsListAddress: Decodable {
    
    let houseId: String?
    let flatId: String?
    let address: String
    let accounts: [APIPaymentsListAccount]
    
}
