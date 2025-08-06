//
//  GateAccessViewModel.swift
//  SmartYard
//
//  Created by Александр Попов on 12.06.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxSwift
import RxCocoa
import RxRelay

final class GateAccessViewModel: BaseViewModel {
        
    let sectionModels = BehaviorRelay<[GateAccessSectionModel]>(value: [])
    
    func update(carData: [AllowedCar]) {
        let footerItem = GateAccessDataItem.shortcut(.allCars)
        let licensePlaces = carData.map { GateAccessDataItem.car($0) }
        let firstFiveLicensePlaces = licensePlaces.prefix(5)
        
        let sectionModel = GateAccessSectionModel(
            identity: "CarSection",
            items: firstFiveLicensePlaces + [footerItem]
        )
        
        sectionModels.accept([sectionModel])
    }
    
    func update(personData: [AllowedPerson]) {
        let footerItem = GateAccessDataItem.shortcut(.allPersons)
        let contacts = personData.map { GateAccessDataItem.person($0) }
        let firstFiveContacts = contacts.prefix(5)
        let sectionModel = GateAccessSectionModel(
            identity: "PersonSection",
            items: firstFiveContacts + [footerItem]
        )
        
        sectionModels.accept([sectionModel])
    }
    
}

