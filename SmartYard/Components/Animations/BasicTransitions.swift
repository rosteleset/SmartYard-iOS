//
//  BasicTransitions.swift
//  SmartYard
//
//  Created by admin on 17/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
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
    
    static func appSettingsTransition(title: String, message: String?) -> Transition {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
        
        let settingsAction = UIAlertAction(title: "Настройки", style: .default) { _ in
            UIApplication.shared.open(
                URL(string: UIApplication.openSettingsURLString)!,
                options: [:],
                completionHandler: nil
            )
        }
        
        alert.addAction(cancelAction)
        alert.addAction(settingsAction)
        
        return .present(alert)
    }
    
}
