//
//  AccessViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

final class AccessViewModel: BaseViewModel {
    
    let sectionModels = BehaviorSubject<[AllowedPersonSectionModel]>(value: [])
    
    func updateData(data: [AllowedPerson]) {
        let headerItem = AllowedPersonDataItem.addContact
        let contacts = data.map { AllowedPersonDataItem.contact(person: $0) }
        
        let sectionModel = AllowedPersonSectionModel(identity: "MainSection", items: contacts + [headerItem])
        sectionModels.onNext([sectionModel])
    }
    
}

