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
    
    func transform(input: Input) -> Output {

        input.awakeFromNibTrigger
            .drive(
                onNext: { [weak self] in
                    self?.personsItemsSubject.onNext([])
                }
            )
            .disposed(by: disposeBag)
        
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
        
        return Output(personsTrigger: personsItemsSubject.asDriver(onErrorJustReturn: []))
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
