//
//  AudioDataItem.swift
//  SmartYard
//
//  Created by devcentra on 07.04.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import Foundation
import AVFoundation
import MessageKit

struct AudioDataItem: AudioItem {
    
    let url: URL
    let duration: Float
    var size: CGSize
    
}
extension AudioDataItem {
    
    init(audiourl: String) {
        self.url = URL(string: audiourl)!
        
//        let audioAsset = AVURLAsset(url: self.url, options: nil)
//        let duration = audioAsset.load(.duration)
//        let seconds = CMTimeGetSeconds(duration)
        let seconds = 3
        self.duration = Float(seconds)
        self.size = CGSize(width: 250, height: 44)
    }
    
}
