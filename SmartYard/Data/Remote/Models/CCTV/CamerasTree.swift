//
//  CamerasTree.swift
//  SmartYard
//
//  Created by Александр Васильев on 27.10.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import Foundation

struct CamerasTree: Decodable, EmptyDataInitializable {
    let groupId: Int?
    let groupName: String?
    let type: CamViewType?
    let childGroups: [CamerasTree]?
    let cameras: [APICCTV]?
    
    init() {
        groupId = nil
        groupName = nil
        type = .map
        childGroups = nil
        cameras = nil
    }
    
    enum CamViewType: String, Decodable {
        case map
        case list
    }
}
