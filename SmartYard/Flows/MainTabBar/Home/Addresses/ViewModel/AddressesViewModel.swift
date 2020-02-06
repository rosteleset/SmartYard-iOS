//
//  AddressesViewModel.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa

class AddressesViewModel: BaseViewModel {
    
    func transform(_ input: Input) -> Output {
        let sectionModels: Driver<[AddressesSectionModel]> = .just(
            [
                AddressesSectionModel(
                    identity: "First",
                    items: [
                        .header(identity: .header(address: "First Header"), address: "г. Тамбов, ул. Советская, 16, кв. 4", isExpanded: false)
                    ]
                )
            ]
        )
        
        return Output(sectionModels: sectionModels)
    }
    
}

extension AddressesViewModel {
    
    struct Input {
        
    }
    
    struct Output {
        let sectionModels: Driver<[AddressesSectionModel]>
    }
    
}
