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
    
    let personsItemsSubject = BehaviorSubject<[AllowedPerson]>(value: [])
    
    func updateData(data: [AllowedPerson]) {
        personsItemsSubject.onNext(data)
    }
    
}

