//
//  APIProvider.swift
//  SmartYard
//
//  Created by LanTa on 13.06.2022.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct APIProvider: Codable {
    let id: String
    let name: String
    let baseUrl: String
    let order: Int?
}
