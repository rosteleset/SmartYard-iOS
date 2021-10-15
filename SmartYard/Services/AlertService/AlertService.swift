//
//  AlertService.swift
//  SmartYard
//
//  Created by admin on 25.05.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

// Мне надо было как-то единообразно разрулить показ алерта "Регистрация на другом устройстве"
// Я хотел, чтобы он всегда был самым важным (показывался поверх остальных) и не мог быть перекрыт другими алертами
// Можно было разруливать это через роутеры, но тогда в каждом роутере пришлось бы копипастить логику
// В лучшем случае, получилось бы что-то вроде того, что сейчас в Д.Авто (композитные роутеры)
// Я решил отвязаться вообще от роутеров и вынести показ алертов в отдельный компонент

// AlertService сейчас дает следующее поведение:
// У каждого алерта есть приоритет. Допустим, мы хотим показать алерт
// Если на экране нет показанных алертов, то просто показываем новый алерт
// Если на экране уже есть показанный алерт, то могут быть два кейса:
// 1) если у нового алерта приоритет больше, то он будет показан вместо предыдущего
// 2) если у нового алерта приоритет <= старого, то ничего не показываем

// Это решает проблему того, что менее важные алерты показываются поверх более важных
// Также это решает проблему спама алертов (на некоторых экрана показывались 2+ алерта поверх друг друга)

// P.S. Выкидывать менее важные алерты - это тоже не особо кайфовая идея.
// По-хорошему нужно как-то суммировать их, то есть показывать информацию обо всех ошибках в одной вьюхе / алерте
// Но пока об этом никто даже не думал, так что хрен с ним

// Сейчас AlertService используется в основном только для показа алерта о необходимости разлогина
// Также в AddressesListViewModel он используется для того, чтобы избежать спама ошибок сети
// В остальных местах пока пусть останется разруливание дефолтных ошибок через роутеры

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
