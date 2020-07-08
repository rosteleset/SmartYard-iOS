//
//  APIArchiveStreamInfo.swift
//  SmartYard
//
//  Created by admin on 08.07.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct APIArchiveStreamInfo: Decodable {
    
    let stream: String
    let ranges: [APIArchiveRange]
    
}
