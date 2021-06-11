//
//  HistoryHelpers.swift
//  SmartYard
//
//  Created by Александр Васильев on 15.04.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit
import PopOverDatePicker

typealias DayFlatItemsData = (day: Date, items: [APIPlog], flatId: Int)

typealias ApptsFilter = Int

enum EventsFilter: Int, CaseIterable {
    case all = 0
    case domophones = 1
    case keys = 2
    case faces = 3
    case phoneCall = 4
    case application = 5
    case code = 6
    
    public var name: String {
        switch self {
        
        case .all:
            return "Все"
        case .domophones:
            return "Домофон"
        case .keys:
            return "Ключом"
        case .faces:
            return "По лицу"
        case .phoneCall:
            return "По номеру телефона"
        case .application:
            return "Приложение"
        case .code:
            return "По коду"
        }
    }
    
    static var allCasesString: [String] {
        let all = EventsFilter.allCases
        return all.map { $0.name }
    }
    
    static var withoutFRSCasesString: [String] {
        let all = EventsFilter.allCases
        return all.filtered({ $0 != .faces }, map: { $0.name }) 
    }
    
}

class AlwaysPresentAsPopover: NSObject, UIPopoverPresentationControllerDelegate {
    
    // `sharedInstance` because the delegate property is weak - the delegate instance needs to be retained.
    private static let sharedInstance = AlwaysPresentAsPopover()
    
    override private init() {
        super.init()
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    static func configurePresentation(forController controller: UIViewController) -> UIPopoverPresentationController? {
        controller.modalPresentationStyle = .popover
        guard let presentationController = controller.presentationController as? UIPopoverPresentationController else {
            return nil
        }
        presentationController.delegate = AlwaysPresentAsPopover.sharedInstance
        return presentationController
    }
    
}

class ArrayChoiceTableViewController<Element>: UITableViewController {
    
    typealias SelectionHandler = (Element, Int) -> Void
    typealias LabelProvider = (Element) -> String
    
    private let values: [Element]
    private let labels: LabelProvider
    private let onSelect: SelectionHandler?
    private var selectedRow: Int = 0
    
    init(_ values: [Element], labels: @escaping LabelProvider = String.init(describing:), selectedRow: Int, onSelect: SelectionHandler? = nil) {
        self.values = values
        self.onSelect = onSelect
        self.labels = labels
        self.selectedRow = selectedRow
        
        super.init(style: .plain)
        self.tableView.separatorColor = .clear
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        
        let sansFont = UIFont(descriptor: UIFontDescriptor(fontAttributes: [.family: "Source Sans Pro"]), size: 16)
        cell.textLabel?.font = sansFont
        cell.textLabel?.text = labels(values[indexPath.row])
        cell.imageView?.image = selectedRow == indexPath.row ? UIImage(named: "PopoverCheckBoxSelected"): UIImage(named: "PopoverCheckBoxNormal")
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let lastState = self.selectedRow
        self.selectedRow = indexPath.row
        tableView.reloadRows(at: [indexPath, IndexPath(row: lastState, section: 0)], with: .none)
        self.dismiss(animated: false)
        onSelect?(values[indexPath.row], selectedRow)
    }
    
}

class UITableViewWithHandler: UITableView {
    //чтобы была возможность скролить табличку, после того, как в неё попали новые данные, пришлось немного модифицировать штатный класс, т.к.
    //RxDataSource штатно из коробки такой возможности не предоставлял
    public var afterUpdateHandler: (() -> Void)? = nil
        
    override func performBatchUpdates(_ updates: (() -> Void)?,
                                      completion: ((Bool) -> Void)? = nil) {
        let modifiedCompletition: ((Bool) -> Void)? = { finished in
            completion?(finished)
            self.afterUpdateHandler?()
        }
        super.performBatchUpdates(updates, completion: modifiedCompletition)
    }
}

extension PopOverDatePickerViewController {
  
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.post(.init(name: .popupDimissed, object: nil))
    }
}
