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
    
    var personsItemsSubject = PublishSubject<[AllowedPerson]>()
    
    func transform(input: Input) -> Output {
        
        input.deletePressedTrigger
            .drive(
                onNext: { atIndex in
                    // TODO
                }
            )
            .disposed(by: disposeBag)
        
        input.addNewPersonTrigger
            .drive(
                onNext: {
                    // TODO
                }
            )
            .disposed(by: disposeBag)
        
        let combined = Driver.combineLatest(
            input.awakeFromNibTrigger.asDriver(onErrorJustReturn: ()),
            personsItemsSubject.asDriver(onErrorJustReturn: [])
        ) { _, persons -> [AllowedPerson] in
            return persons
        }
        
        return Output(personsTrigger: combined.asDriver(onErrorJustReturn: []))
    }
    
    func updateData(data: [AllowedPerson]) {
        print("UPDATE DATA!!!")
        personsItemsSubject.onNext(data)
    }
    
}

extension AccessViewModel {
    
    struct Input {
        let deletePressedTrigger: Driver<Int?>
        let addNewPersonTrigger: Driver<Void>
        let awakeFromNibTrigger: Driver<Void>
    }
    
    struct Output {
        let personsTrigger: Driver<[AllowedPerson]>
    }
    
}
