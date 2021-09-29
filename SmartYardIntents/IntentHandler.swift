//
//  IntentHandler.swift
//  SmartYardIntents
//
//  Created by Александр Васильев on 26.09.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Intents

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any? {
        if intent is SYOpenDoorIntent {
            return SYOpenDoorIntentHandler()
        }
        
        return nil
    }
    
}
