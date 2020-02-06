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
        let sectionModels: Driver<[AddressesSectionModel]> = .just(createMockSections())
        
        return Output(sectionModels: sectionModels)
    }
    
    private func createMockSections() -> [AddressesSectionModel] {
        let firstSectionFirstItem: AddressesDataItem = .header(
            identity: .header(address: "FirstSectionHeader"),
            address: "г. Тамбов, ул. Советская, 16, кв. 4",
            isExpanded: false
        )
        
        let firstSection = AddressesSectionModel(identity: "FirstSection", items: [firstSectionFirstItem])
        
        let secondSectionFirstItem: AddressesDataItem = .header(
            identity: .header(address: "SecondSectionHeader"),
            address: "г. Тамбов, ул. Мичуринская, 141А",
            isExpanded: false
        )
        
        let secondSection = AddressesSectionModel(identity: "SecondSection", items: [secondSectionFirstItem])
        
        let thirdSectionFirstItem: AddressesDataItem = .header(
            identity: .header(address: "ThirdSectionHeader"),
            address: "г. Котовск, ул. Зимняя, 20",
            isExpanded: false
        )
        
        let thirdSection = AddressesSectionModel(identity: "ThirdSection", items: [thirdSectionFirstItem])
        
        return [firstSection, secondSection, thirdSection]
    }
    
}

extension AddressesViewModel {
    
    struct Input {
        
    }
    
    struct Output {
        let sectionModels: Driver<[AddressesSectionModel]>
    }
    
}
