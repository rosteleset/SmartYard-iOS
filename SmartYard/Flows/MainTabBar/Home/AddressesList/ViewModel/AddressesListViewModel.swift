//
//  AddressesViewModel.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa

class AddressesListViewModel: BaseViewModel {
    
    func transform(_ input: Input) -> Output {
        let sectionModels: Driver<[AddressesListSectionModel]> = .just(createMockSections())
        
        return Output(sectionModels: sectionModels)
    }
    
    private func createMockSections() -> [AddressesListSectionModel] {
        let firstSectionFirstItem: AddressesListDataItem = .header(
            identity: .header(address: "FirstSectionHeader"),
            address: "г. Тамбов, ул. Советская, 16, кв. 4",
            isExpanded: false
        )
        
        let firstSection = AddressesListSectionModel(identity: "FirstSection", items: [firstSectionFirstItem])
        
        let secondSectionFirstItem: AddressesListDataItem = .header(
            identity: .header(address: "SecondSectionHeader"),
            address: "г. Тамбов, ул. Мичуринская, 141А",
            isExpanded: false
        )
        
        let secondSection = AddressesListSectionModel(identity: "SecondSection", items: [secondSectionFirstItem])
        
        let thirdSectionFirstItem: AddressesListDataItem = .header(
            identity: .header(address: "ThirdSectionHeader"),
            address: "г. Котовск, ул. Зимняя, 20",
            isExpanded: false
        )
        
        let thirdSection = AddressesListSectionModel(identity: "ThirdSection", items: [thirdSectionFirstItem])
        
        return [firstSection, secondSection, thirdSection]
    }
    
}

extension AddressesListViewModel {
    
    struct Input {
        
    }
    
    struct Output {
        let sectionModels: Driver<[AddressesListSectionModel]>
    }
    
}
