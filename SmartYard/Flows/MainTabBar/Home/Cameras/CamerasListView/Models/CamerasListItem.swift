//
//  CamerasListItem.swift
//  SmartYard
//
//  Created by Александр Васильев on 19.10.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import Foundation
import UIKit

enum CamerasListItem {
    case caption(label: String)
    case group(label: String, id: Int, tree: [CamerasTree])
    case mapView(label: String, id: Int, cameras: [CameraObject])
    case camera(camera: CameraObject)
    
    var label: String {
        switch self {
        case .caption(label: let label):
            return label
        case .group(label: let label, id: _, tree: _):
            return label
        case .camera(camera: let camera):
            return camera.name
        case .mapView(let label, _, _):
            return label
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .caption:
            return nil
        case .group, .mapView:
            return UIImage(named: "RightArrowIcon")
        case .camera:
            return UIImage(named: "CameraIcon")
        }
    }
    
    var id: Int {
        switch self {
        case .group(label: _, id: let id, tree: _):
            return id
        case .mapView(label: _, id: let id, cameras: _):
            return id
        default:
            return 0
        }
    }
    
}
