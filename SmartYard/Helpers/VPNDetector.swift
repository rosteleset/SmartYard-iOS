//
//  VPNDetector.swift
//  SmartYard
//
//  Created by Александр Попов on 19.09.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import Foundation
import CFNetwork

enum VPNDetector {
    static var isVPNActive: Bool {
        guard let cfDict = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? NSDictionary,
              let scoped = cfDict["__SCOPED__"] as? [String: Any] else {
            return false
        }
        let protocols = Set(["tap", "tun", "ppp", "ispec", "utun"])

        return scoped.keys.contains { key in
            protocols.contains { key.hasPrefix($0) }
        }
    }
}
