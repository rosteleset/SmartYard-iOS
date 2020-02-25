//
//  HourGuestAccessResponseData.swift
//  SmartYard
//
//  Created by Mad Brains on 21.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

struct IntercomResponseData: Decodable {
    
    let allowDoorCode: String
    let doorCode: String?
    let cms: String
    let voip: String
    let autoOpen: String
    let whiteRabbit: String
    
    private enum CodingKeys: String, CodingKey {
        case allowDoorCode
        case doorCode
        case cms = "CMS"
        case voip = "VoIP"
        case autoOpen
        case whiteRabbit
    }
    
}
