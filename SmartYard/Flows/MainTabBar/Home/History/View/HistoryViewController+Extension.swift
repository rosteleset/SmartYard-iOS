//
//  HistoryViewController+Extension.swift
//  SmartYard
//
//  Created by Александр Васильев on 15.04.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit

extension HistoryViewController {
    public func showPopup(_ controller: UIViewController, sourceView: UIView) {
        guard let presentationController = AlwaysPresentAsPopover.configurePresentation(forController: controller) else {
            return
        }
        presentationController.sourceView = sourceView
        presentationController.sourceRect = sourceView.bounds
        presentationController.permittedArrowDirections = [.down, .up]
        self.present(controller, animated: true)
    }
    
    public func showEventsFilterPopover(from sourceView: UIView, _ onSelect: @escaping (String, Int) -> Void ) {
        //let controller = EventsPopup()
        
        let items = EventsFilter.allCasesString
        
        let controller = ArrayChoiceTableViewController(items, selectedRow: eventsFilter.rawValue,
                                                        onSelect: onSelect)
        
        controller.preferredContentSize = CGSize(width: Int(self.view.width) - 32, height: EventsFilter.allCases.count * 45)
        showPopup(controller, sourceView: sourceView)
    }
}
