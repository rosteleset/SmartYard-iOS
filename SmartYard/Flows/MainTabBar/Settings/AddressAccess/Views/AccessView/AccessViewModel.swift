//
//  AccessViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class AccessViewModel: BaseViewModel {
    
    let sectionModels = BehaviorSubject<[AllowedPersonSectionModel]>(value: [])
    
    func updateData(allowedPersonType: AllowedPersonType, data: [AllowedPerson]) {
        let headerItem = AllowedPersonDataItem.addContact
        let contacts = data.map { AllowedPersonDataItem.contact(personType: allowedPersonType, person: $0) }
        
        let sectionModel = AllowedPersonSectionModel(identity: "MainSection", items: contacts + [headerItem])
        sectionModels.onNext([sectionModel])
    }
    
}

