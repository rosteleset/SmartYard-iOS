//
//  UIDevice+Extensions.swift
//  SmartYard
//
//  Created by Александр Попов on 05.08.2024.
//  Copyright © 2024 LanTa. All rights reserved.
//

import UIKit

public extension UIDevice {
    
    /// pares the deveice name as the standard name
    var modelName: String {
        
#if targetEnvironment(simulator)
        let identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"]!
#else
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
#endif
        
        return identifier
    }
}
