//
//  AlertService.swift
//  SmartYard
//
//  Created by admin on 25.05.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class AlertService {
    
    private var priorities = [UIAlertController: Int]()
    
    func showAlert(title: String, message: String?, priority: Int) {
        let okAction = UIAlertAction(title: "OK", style: .cancel)
        
        showDialog(title: title, message: message, actions: [okAction], priority: priority)
    }
    
    func showDialog(title: String, message: String?, actions: [UIAlertAction], priority: Int) {
        // MARK: Проверяем, есть ли вообще VC, от которого можно показать alert
        
        guard let topVc = UIApplication.shared.keyWindow?.rootViewController?.topViewController else {
            return
        }
        
        // MARK: Создаем alert
        
        let newAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        actions.forEach {
            newAlert.addAction($0)
        }
        
        // MARK: Если верхний VC не является alert - просто показываем новый alert от topVc
        
        guard let topAlert = topVc as? UIAlertController else {
            priorities[newAlert] = priority
            
            topVc.present(newAlert, animated: true)
            
            return
        }
        
        // MARK: Если верхний VC - это уже alert, проверяем приоритеты.
        // Если приоритет нового alert ниже - ничего не делаем
        // Если приоритет нового alert выше - скрываем предыдущий alert и показываем новый
        
        guard priority > priorities[topAlert] ?? 0 else {
            return
        }
        
        topAlert.dismiss(animated: false) { [weak self] in
            let newTopVc = UIApplication.shared.keyWindow?.rootViewController?.topViewController
            
            self?.priorities[newAlert] = priority
            
            newTopVc?.present(newAlert, animated: false)
        }
    }
    
}
