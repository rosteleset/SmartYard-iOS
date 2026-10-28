//
//  OnlineCameraViewModel.swift
//  SmartYard
//
//  Created by Александр Попов on 25.12.2025.
//  Copyright © 2025 Sesameware. All rights reserved.
//

import Foundation

struct CameraViewCellModel: Equatable {
    let identity: String
    let id: CameraID
    let previewURL: URL?
    let isMuted: Bool
}
