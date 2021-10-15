//
//  SharedFunctions.swift
//  SmartYard
//
//  Created by Александр Васильев on 29.09.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import Intents
import SmartYardSharedDataFramework

public enum SmartYardSharedFunctions {
    public static func donateInteraction(_ object: SmartYardSharedObject) {
            
        if #available(iOS 14.0, *) {
            let intent = SYOpenDoorIntent()
        
            intent.doorType = .any
            intent.address = HouseAddress(identifier: object.objectAddress, display: object.objectAddress)
            intent.door = Door(identifier: object.objectName, display: object.objectName)
            
            let interaction = INInteraction(
                intent: intent,
                response: SYOpenDoorIntentResponse(code: .success, userActivity: nil)
            )
                
            interaction.donate()
        }
    }
}
