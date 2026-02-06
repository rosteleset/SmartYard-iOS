//
//  OnlineSelectionUpdate.swift
//  SmartYard
//
//  Created by Александр Попов on 23.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

enum OnlineSelectionSource {
    case preselected
    case mainCentered
    case numberTap
}

extension OnlineSelectionSource {
    var logValue: String {
        switch self {
        case .preselected: return "preselected"
        case .mainCentered: return "mainCentered"
        case .numberTap: return "numberTap"
        }
    }
}

struct OnlineSelectionUpdate: Equatable {
    let id: CameraID
    let source: OnlineSelectionSource
}
