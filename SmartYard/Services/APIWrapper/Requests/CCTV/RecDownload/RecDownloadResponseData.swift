//
//  RecDownloadResponse.swift
//  SmartYard
//
//  Created by admin on 15.06.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

struct RecDownloadResponseData: Decodable, EmptyDataInitializable {
    
    let url: String?
    
    init() {
        url = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // параметр url - опциональный, потому что может прийти код 204 без урла
        // если пришел 204, инициализируем с url = nil
        // если пришел 200, то url обязательно должен быть. поэтому try без вопросительного знака
        url = try container.decode(String.self)
    }
    
}
