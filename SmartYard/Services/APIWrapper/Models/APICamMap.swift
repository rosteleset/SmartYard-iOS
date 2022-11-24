//
//  APICamMap.swift
//  SmartYard
//
//  Created by Александр Васильев on 27.04.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct APICamMap: Decodable {
    /// Id домофона
    let id: Int
    
    /// базовый url потока
    let url: String
    
    /// token
    let token: String
    
    let serverType: DVRServerType
    
    private enum CodingKeys: String, CodingKey {
        case id
        case url
        case token
        case serverType
    }
    
    var liveURL: String {
        switch self.serverType {
        case .nimble:
            return "\(url)/playlist.m3u8?wmsAuthSign=\(token)"
        default:
            return "\(url)/index.m3u8?token=\(token)"
        }
    }
    
    func archiveURL(urlComponents: String) -> String {
        switch self.serverType {
        case .nimble:
            return "\(url)/playlist_dvr_range-\(urlComponents).m3u8?wmsAuthSign=\(token)"
        default:
            return "\(url)/index-\(urlComponents).m3u8?token=\(token)"
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = Int(try container.decode(String.self, forKey: .id)) ?? 0
        url = try container.decode(String.self, forKey: .url)
        token = try container.decode(String.self, forKey: .token)
        serverType = (try? container.decode(DVRServerType.self, forKey: .serverType)) ?? .flussonic
    }
    
}
