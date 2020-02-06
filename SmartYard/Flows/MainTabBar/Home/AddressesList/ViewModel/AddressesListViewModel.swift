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
            identity: .header(id: "FirstSectionHeader"),
            address: "г. Тамбов, ул. Советская, 16, кв. 4",
            isExpanded: true
        )
        
        let firstSectionSecondItem: AddressesListDataItem = .object(
            identity: .object(id: "FirstSectionFirstObject"),
            type: .barrier,
            name: "Шлагбаум Север",
            isOpened: false
        )
        
        let firstSectionThirdItem: AddressesListDataItem = .object(
            identity: .object(id: "FirstSectionSecondObject"),
            type: .gate,
            name: "Ворота Юг",
            isOpened: false
        )
        
        let firstSectionFourthItem: AddressesListDataItem = .object(
            identity: .object(id: "FirstSectionThirdObject"),
            type: .house,
            name: "Подъезд 1",
            isOpened: true
        )

        let firstSection = AddressesListSectionModel(
            identity: "FirstSection",
            items: [firstSectionFirstItem, firstSectionSecondItem, firstSectionThirdItem, firstSectionFourthItem]
        )
        
        let secondSectionFirstItem: AddressesListDataItem = .header(
            identity: .header(id: "SecondSectionHeader"),
            address: "г. Тамбов, ул. Мичуринская, 141А",
            isExpanded: false
        )
        
        let secondSection = AddressesListSectionModel(identity: "SecondSection", items: [secondSectionFirstItem])
        
        let thirdSectionFirstItem: AddressesListDataItem = .header(
            identity: .header(id: "ThirdSectionHeader"),
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
