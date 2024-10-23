//
//  HistoryViewController+Extension.swift
//  SmartYard
//
//  Created by Александр Васильев on 15.04.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit
import PopOverDatePicker

extension HistoryViewController {
    private func showPopup(_ controller: UIViewController, sourceView: UIView) {
        guard let presentationController = AlwaysPresentAsPopover.configurePresentation(forController: controller) else {
            return
        }
        presentationController.sourceView = sourceView
        presentationController.sourceRect = sourceView.bounds
        presentationController.permittedArrowDirections = [.down, .up]
        self.present(controller, animated: true)
    }
    
    public func showEventsFilterPopover(from sourceView: UIView, items: [String], onSelect: @escaping (String, Int) -> Void ) {
        let controller = ArrayChoiceTableViewController(
            items,
            selectedRow: items.firstIndex(of: eventsFilter.value.name) ?? 0,
            onSelect: onSelect
        )
        
        controller.preferredContentSize = CGSize(width: Int(self.view.width) - 32, height: items.count * 45)
        showPopup(controller, sourceView: sourceView)
    }
    
    public func showAppartmentsFilterPopover(from sourceView: UIView, items: [String], selectedRow: Int, onSelect: @escaping (String, Int) -> Void ) {
        let items = items
        
        let controller = ArrayChoiceTableViewController(
            items,
            selectedRow: selectedRow,
            onSelect: onSelect
        )
        
        controller.preferredContentSize = CGSize(width: Int(self.view.width) - 32, height: items.count * 45)
        showPopup(controller, sourceView: sourceView)
    }
    
    public func showCalendarPopover(
        from sourceView: UIView,
        minDate: Date,
        maxDate: Date,
        onSelect: @escaping (Date) -> Void
    ) {
        let date = Date()
        
        let popOverDatePickerViewController = SYPopOverDatePickerViewController.instantiate()
        popOverDatePickerViewController.set(date: date)
        popOverDatePickerViewController.set(minimumDate: minDate)
        popOverDatePickerViewController.set(maximumDate: maxDate)
        popOverDatePickerViewController.set(datePickerMode: .date)
        popOverDatePickerViewController.set(locale: Calendar.current.locale ?? Locale(identifier: "ru-RU"))
        popOverDatePickerViewController.set(timeZone: Calendar.serverCalendar.timeZone)
        popOverDatePickerViewController.presentationController?.delegate = self
        popOverDatePickerViewController.changeHandler = onSelect
        
        showPopup(popOverDatePickerViewController, sourceView: sourceView)
    }
    
}
