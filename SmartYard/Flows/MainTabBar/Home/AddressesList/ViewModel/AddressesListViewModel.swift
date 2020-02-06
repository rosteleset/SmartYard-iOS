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
    
    private let areSectionsExpanded = BehaviorSubject<[String: Bool]>(value: [:])
    
    func transform(_ input: Input) -> Output {
        // MARK: Скрытие / раскрытие секции
        
        input.itemSelected
            .flatMap { identity -> Driver<String> in
                guard case let .header(addressId) = identity else {
                    return .empty()
                }
                
                return .just(addressId)
            }
            .withLatestFrom(areSectionsExpanded.asDriverOnErrorJustComplete()) { ($0, $1) }
            .map { args in
                var (updatedId, dict) = args
                
                let newState = !dict[updatedId, default: false]
                dict[updatedId] = newState
                
                return dict
            }
            .drive(
                onNext: { [weak self] newDict in
                    self?.areSectionsExpanded.onNext(newDict)
                }
            )
            .disposed(by: disposeBag)
        
        let sectionModels = areSectionsExpanded
            .map { [weak self] dict in
                self?.createMockSections(expansionStateDict: dict) ?? []
            }
        
        return Output(sectionModels: sectionModels.asDriverOnErrorJustComplete())
    }
    
    // swiftlint:disable:next function_body_length
    private func createMockSections(expansionStateDict: [String: Bool]) -> [AddressesListSectionModel] {
        let firstAddressId = "1000"
        let isFirstSectionExpanded = expansionStateDict[firstAddressId, default: false]
        
        let firstSectionHeader: AddressesListDataItem = .header(
            identity: .header(addressId: firstAddressId),
            address: "г. Тамбов, ул. Советская, 16, кв. 4",
            isExpanded: isFirstSectionExpanded
        )
        
        // swiftlint:disable:next closure_body_length
        let firstSectionObjects: [AddressesListDataItem] = {
            guard isFirstSectionExpanded else {
                return []
            }
            
            let firstSectionFirstObject: AddressesListDataItem = .object(
                identity: .object(id: "FirstSectionFirstObject"),
                type: .barrier,
                name: "Шлагбаум Север",
                isOpened: false
            )
            
            let firstSectionSecondObject: AddressesListDataItem = .object(
                identity: .object(id: "FirstSectionSecondObject"),
                type: .gate,
                name: "Ворота Юг",
                isOpened: false
            )
            
            let firstSectionThirdObject: AddressesListDataItem = .object(
                identity: .object(id: "FirstSectionThirdObject"),
                type: .house,
                name: "Подъезд 1",
                isOpened: true
            )
            
            let firstSectionCameraObject: AddressesListDataItem = .cameras(
                identity: .cameras(addressId: firstAddressId),
                numberOfCameras: 3
            )
            
            return [
                firstSectionFirstObject,
                firstSectionSecondObject,
                firstSectionThirdObject,
                firstSectionCameraObject
            ]
        }()

        let firstSection = AddressesListSectionModel(
            identity: firstAddressId,
            items: [firstSectionHeader] + firstSectionObjects
        )
        
        let secondAddressId = "2000"
        let isSecondSectionExpanded = expansionStateDict[secondAddressId, default: false]
        
        let secondSectionHeader: AddressesListDataItem = .header(
            identity: .header(addressId: secondAddressId),
            address: "г. Тамбов, ул. Мичуринская, 141А",
            isExpanded: isSecondSectionExpanded
        )
        
        let secondSection = AddressesListSectionModel(identity: secondAddressId, items: [secondSectionHeader])
        
        let thirdAddressId = "3000"
        let isThirdSectionExpanded = expansionStateDict[thirdAddressId, default: false]
        
        let thirdSectionHeader: AddressesListDataItem = .header(
            identity: .header(addressId: thirdAddressId),
            address: "г. Котовск, ул. Зимняя, 20",
            isExpanded: isThirdSectionExpanded
        )
        
        let thirdSection = AddressesListSectionModel(identity: "3000", items: [thirdSectionHeader])
        
        return [firstSection, secondSection, thirdSection]
    }
    
}

extension AddressesListViewModel {
    
    struct Input {
        let itemSelected: Driver<AddressesListDataItemIdentity>
    }
    
    struct Output {
        let sectionModels: Driver<[AddressesListSectionModel]>
    }
    
}
