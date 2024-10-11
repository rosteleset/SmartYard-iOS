//
//  ShareGenerateResponseData.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 18.04.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation

struct ShareGenerateResponseData: Decodable {
    
    let title: String
    let text: String
    let url: URL?

    private enum CodingKeys: String, CodingKey {
        case title
        case text
        case url
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        title = try container.decode(String.self, forKey: .title)
        text = try container.decode(String.self, forKey: .text)
        
        let urlString = try? container.decode(String.self, forKey: .url)

        url = URL(string: urlString)
    }
}
