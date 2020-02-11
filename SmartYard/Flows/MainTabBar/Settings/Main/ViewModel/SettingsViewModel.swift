//
//  SettingsViewModel.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

class SettingsViewModel: BaseViewModel {
    
    private let router: WeakRouter<SettingsRoute>
    
    // MARK: Словарь необходим для того, чтобы хранить состояния раскрытости секций
    private let areSectionsExpanded = BehaviorSubject<[String: Bool]>(value: [:])
    
    init(router: WeakRouter<SettingsRoute>) {
        self.router = router
    }
    
    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        // MARK: Обработка нажатия на настройки адреса
        
        input.itemSelected
            .flatMap { identity -> Driver<String> in
                guard case let .action(_, address, type) = identity, type == .openAddressSettings else {
                    return .empty()
                }
                
                return .just(address)
            }
            .drive(
                onNext: { [weak self] address in
                    self?.router.trigger(.addressSettings(address: address))
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: При скрытии / раскрытии секций передаем информацию о секции, чтобы View могла выполнить скроллинг
        
        let updateKindSubject = PublishSubject<SettingsSectionUpdateKind>()
        let updateKind = updateKindSubject.asDriverOnErrorJustComplete()
        
        // MARK: При нажатии на Header, обновляем состояние раскрытости для этой секции
        // Это приведет к обновлению секций
        
        input.itemSelected
            .flatMap { identity -> Driver<String> in
                guard case let .header(addressId) = identity else {
                    return .empty()
                }
                
                return .just(addressId)
            }
            .withLatestFrom(areSectionsExpanded.asDriverOnErrorJustComplete()) { ($0, $1) }
            .map { args -> ((String, Bool), [String: Bool]) in
                var (addressId, dict) = args
                
                let newState = !dict[addressId, default: false]
                dict[addressId] = newState
                
                return ((addressId, newState), dict)
            }
            
            // MARK: Вынес в блок do, чтобы не делать сайд-эффектов в map
            
            .do(
                onNext: { args in
                    let (updatedSectionInfo, _) = args
                    let (addressId, newState) = updatedSectionInfo
                    
                    let identity = SettingsDataItemIdentity.header(addressId: addressId)
                    
                    updateKindSubject.onNext(
                        newState ?
                            .expand(sectionWithIdentity: identity) :
                            .collapse(sectionWithIdentity: identity)
                    )
                }
            )
            .map { args in
                let (_, dict) = args
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
        
        return Output(
            sectionModels: sectionModels.asDriverOnErrorJustComplete(),
            updateKind: updateKind
        )
    }
    
    // swiftlint:disable:next function_body_length
    private func createMockSections(expansionStateDict: [String: Bool]) -> [SettingsSectionModel] {
        // MARK: Пока моки, но в принципе, нет ничего сложного прикрутить сюда реальные данные
        // Просто будем пробегать в цикле по всем адресам и генерировать для них секции
        
        let firstAddressId = "1000"
        let firstAddress = "г. Тамбов, ул. Советская, 16, кв. 4"
        let isFirstSectionExpanded = expansionStateDict[firstAddressId, default: false]
        
        let firstSectionHeader: SettingsDataItem = .header(
            identity: .header(addressId: firstAddressId),
            title: firstAddress,
            subtitle: "Номер договора: 68992",
            isExpanded: isFirstSectionExpanded
        )
        
        // swiftlint:disable:next closure_body_length
        let firstSectionObjects: [SettingsDataItem] = {
            guard isFirstSectionExpanded else {
                return []
            }
            
            let firstSectionControlPanel: SettingsDataItem = .controlPanel(
                identity: .controlPanel(addressId: firstAddressId),
                isWiFiEnabled: true,
                isMonitorEnabled: false,
                isCallEnabled: true,
                isKeyEnabled: false,
                isEyeEnabled: false
            )
            
            let firstSectionFirstAction: SettingsDataItem = .action(
                identity: .action(
                    addressId: firstAddressId,
                    address: firstAddress,
                    type: .openAddressSettings
                )
            )
            
            let firstSectionSecondAction: SettingsDataItem = .action(
                identity: .action(
                    addressId: firstAddressId,
                    address: firstAddress,
                    type: .grantAccess
                )
            )
            
            let firstSectionThirdAction: SettingsDataItem = .action(
                identity: .action(
                    addressId: firstAddressId,
                    address: firstAddress,
                    type: .openWebVersion
                )
            )
            
            return [
                firstSectionControlPanel,
                firstSectionFirstAction,
                firstSectionSecondAction,
                firstSectionThirdAction
            ]
        }()
        
        let firstSection = SettingsSectionModel(
            identity: firstAddressId,
            items: [firstSectionHeader] + firstSectionObjects
        )
        
        let secondAddressId = "2000"
        let secondAddress = "г. Тамбов, ул. Мичуринская, 141А"
        let isSecondSectionExpanded = expansionStateDict[secondAddressId, default: false]
        
        let secondSectionHeader: SettingsDataItem = .header(
            identity: .header(addressId: secondAddressId),
            title: secondAddress,
            subtitle: "Номер договора: 69325",
            isExpanded: isSecondSectionExpanded
        )
        
        // swiftlint:disable:next closure_body_length
        let secondSectionObjects: [SettingsDataItem] = {
            guard isSecondSectionExpanded else {
                return []
            }
            
            let secondSectionControlPanel: SettingsDataItem = .controlPanel(
                identity: .controlPanel(addressId: secondAddressId),
                isWiFiEnabled: true,
                isMonitorEnabled: true,
                isCallEnabled: true,
                isKeyEnabled: true,
                isEyeEnabled: true
            )
            
            let secondSectionFirstAction: SettingsDataItem = .action(
                identity: .action(
                    addressId: secondAddressId,
                    address: secondAddress,
                    type: .openAddressSettings
                )
            )
            
            let secondSectionSecondAction: SettingsDataItem = .action(
                identity: .action(
                    addressId: secondAddressId,
                    address: secondAddress,
                    type: .grantAccess
                )
            )
            
            let secondSectionThirdAction: SettingsDataItem = .action(
                identity: .action(
                    addressId: secondAddressId,
                    address: secondAddress,
                    type: .openWebVersion
                )
            )
            
            return [
                secondSectionControlPanel,
                secondSectionFirstAction,
                secondSectionSecondAction,
                secondSectionThirdAction
            ]
        }()
        
        let secondSection = SettingsSectionModel(
            identity: secondAddressId,
            items: [secondSectionHeader] + secondSectionObjects
        )
        
        let thirdAddressId = "3000"
        let thirdAddress = "г. Котовск, ул. Зимняя, 20"
        let isThirdSectionExpanded = expansionStateDict[thirdAddressId, default: false]
        
        let thirdSectionHeader: SettingsDataItem = .header(
            identity: .header(addressId: thirdAddressId),
            title: thirdAddress,
            subtitle: "Номер договора: 69325",
            isExpanded: isThirdSectionExpanded
        )
        
        // swiftlint:disable:next closure_body_length
        let thirdSectionObjects: [SettingsDataItem] = {
            guard isThirdSectionExpanded else {
                return []
            }
            
            let thirdSectionControlPanel: SettingsDataItem = .controlPanel(
                identity: .controlPanel(addressId: thirdAddressId),
                isWiFiEnabled: false,
                isMonitorEnabled: false,
                isCallEnabled: true,
                isKeyEnabled: true,
                isEyeEnabled: false
            )
            
            let thirdSectionFirstAction: SettingsDataItem = .action(
                identity: .action(
                    addressId: thirdAddressId,
                    address: thirdAddress,
                    type: .openAddressSettings
                )
            )
            
            let thirdSectionSecondAction: SettingsDataItem = .action(
                identity: .action(
                    addressId: thirdAddressId,
                    address: thirdAddress,
                    type: .grantAccess
                )
            )
            
            let thirdSectionThirdAction: SettingsDataItem = .action(
                identity: .action(
                    addressId: thirdAddressId,
                    address: thirdAddress,
                    type: .openWebVersion
                )
            )
            
            return [
                thirdSectionControlPanel,
                thirdSectionFirstAction,
                thirdSectionSecondAction,
                thirdSectionThirdAction
            ]
        }()
        
        let thirdSection = SettingsSectionModel(
            identity: thirdAddressId,
            items: [thirdSectionHeader] + thirdSectionObjects
        )
        
        let addAddressSection = SettingsSectionModel(
            identity: "AddAddressSection",
            items: [SettingsDataItem.addAddress]
        )
        
        return [firstSection, secondSection, thirdSection, addAddressSection]
    }
    
}

extension SettingsViewModel {
    
    struct Input {
        let itemSelected: Driver<SettingsDataItemIdentity>
    }
    
    struct Output {
        let sectionModels: Driver<[SettingsSectionModel]>
        let updateKind: Driver<SettingsSectionUpdateKind>
    }
    
}
