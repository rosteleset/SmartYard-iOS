//
//  ArchiveVideoPlaybackSpeed.swift
//  SmartYard
//
//  Created by admin on 06.07.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

indirect enum ArchiveVideoPlaybackSpeed {
    
    case quarter
    case half
    case normal
    case double
    case quad
    case octo
    case hex
    
    var previousSpeed: ArchiveVideoPlaybackSpeed? {
        switch self {
        case .quarter: return nil
        case .half: return .quarter
        case .normal: return .half
        case .double: return .normal
        case .quad: return .double
        case .octo: return .quad
        case .hex: return .octo
        }
    }
    
    var nextSpeed: ArchiveVideoPlaybackSpeed? {
        switch self {
        case .quarter: return .half
        case .half: return .normal
        case .normal: return .double
        case .double: return .quad
        case .quad: return .octo
        case .octo: return .hex
        case .hex: return nil
        }
    }
    
    var title: String {
        switch self {
        case .quarter: return "0.25x"
        case .half: return "0.5x"
        case .normal: return "1x"
        case .double: return "2x"
        case .quad: return "4x"
        case .octo: return "8x"
        case .hex: return "16x"
        }
    }
    
    var value: Float {
        switch self {
        case .quarter: return 0.25
        case .half: return 0.5
        case .normal: return 1.0
        case .double: return 2.0
        case .quad: return 4.0
        case .octo: return 8.0
        case .hex: return 16.0
        }
    }
    
}
