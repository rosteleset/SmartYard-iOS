//
//  ChatConfiguration.swift
//  SmartYard
//
//  Created by admin on 31/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

struct ChatConfiguration: Equatable {
    
    let id = AccessService().chatId
    let domain = AccessService().chatDomain
    
    let language: String?
    let clientId: String?
    
}
