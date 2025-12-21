//
//  APIClientName.swift
//  SmartYard
//
//  Created by admin on 17/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

struct APIClientName: Codable {
    
    let name: String
    let patronymic: String?
    
    init(name: String, patronymic: String?) {
        self.name = name
        self.patronymic = patronymic
    }
    
}
