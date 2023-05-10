//
//  APISender.swift
//  SmartYard
//
//  Created by devcentra on 31.03.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

struct APISender: Decodable {
    
    let id: Int
    let additionalAttributes: [String]?
    let customAttributes: [String]?
    let email: String?
    let identifier: String?
    let name: String
    let phoneNumber: String?
    let thumbnail: String?
    let type: String
    let availableName: String?
    let avatarUrl: String?
    let availabilityStatus: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case additionalAttributes = "additional_attributes"
        case customAttributes = "custom_attributes"
        case email
        case identifier
        case name
        case phoneNumber = "phone_number"
        case thumbnail
        case type
        case availableName = "available_name"
        case avatarUrl = "avatar_url"
        case availabilityStatus = "availability_status"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)

        additionalAttributes = try? container.decode([String].self, forKey: .additionalAttributes)
        customAttributes = try? container.decode([String].self, forKey: .customAttributes)
        
        email = try? container.decode(String.self, forKey: .email)
        identifier = try? container.decode(String.self, forKey: .identifier)

        name = try container.decode(String.self, forKey: .name)

        phoneNumber = try? container.decode(String.self, forKey: .phoneNumber)
        thumbnail = try? container.decode(String.self, forKey: .thumbnail)

        type = try container.decode(String.self, forKey: .type)

        availableName = try? container.decode(String.self, forKey: .availableName)
        avatarUrl = try? container.decode(String.self, forKey: .avatarUrl)
        availabilityStatus = try? container.decode(String.self, forKey: .availabilityStatus)

    }
}
