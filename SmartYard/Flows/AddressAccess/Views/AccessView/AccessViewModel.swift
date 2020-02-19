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
    
    private let personsItemsSubject = PublishSubject<[AllowedPerson]>()
    
    func transform(input: Input) -> Output {
        let combined = Driver.combineLatest(
            input.awakeFromNibTrigger.asDriver(onErrorJustReturn: ()),
            personsItemsSubject.asDriver(onErrorJustReturn: [])
        ) { _, persons -> [AllowedPerson] in
            persons
        }
        
        return Output(personsTrigger: combined.asDriver(onErrorJustReturn: []))
    }
    
    func updateData(data: [AllowedPerson]) {
        personsItemsSubject.onNext(data)
    }
    
}

extension AccessViewModel {
    
    struct Input {
        let awakeFromNibTrigger: Driver<Void>
    }
    
    struct Output {
        let personsTrigger: Driver<[AllowedPerson]>
    }
    
}
