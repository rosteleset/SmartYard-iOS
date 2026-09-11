//
//  APIProvider.swift
//  SmartYard
//
//  Created by Sesameware on 13.06.2022.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import Foundation

struct APIProvider: Codable {
    let id: String
    let name: String
    let baseUrl: String
    let order: Int?
}
