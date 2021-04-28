//
//  AVPlayer+Extensions.swift
//  SmartYard
//
//  Created by Александр Васильев on 28.04.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import AVFoundation

extension AVPlayer {
    
   func seek(_ toSeconds: Int) {
        let seekTo = self.currentTime() + CMTime(seconds: Double(toSeconds), preferredTimescale: 1)
        self.seek(to: seekTo)
     }

}
