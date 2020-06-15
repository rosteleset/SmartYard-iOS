//
//  BasicTransitions.swift
//  SmartYard
//
//  Created by admin on 17/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import XCoordinator

extension Transition {
    
    static func alertTransition(title: String, message: String?) -> Transition {
        let alert = UIAlertController(title: title, message: message)
        return .present(alert)
    }
    
    static func dialogTransition(title: String, message: String?, actions: [UIAlertAction]) -> Transition {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        actions.forEach {
            alert.addAction($0)
        }
        
        return .present(alert)
    }
    
    static func shareTransition(items: [Any]) -> Transition {
        let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        return .present(activityController)
    }
    
}
